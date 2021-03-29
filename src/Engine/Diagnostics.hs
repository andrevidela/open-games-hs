{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DataKinds, GADTs, TypeFamilies, FlexibleInstances, FlexibleContexts, PolyKinds, ScopedTypeVariables, MultiParamTypeClasses, UndecidableInstances, TypeApplications #-}



module Engine.Diagnostics (  DiagnosticInfoBayesian(..)
                          , DiagnosticInfoPure(..)
                          , generateOutput
                          , generateIsEq
                          )
                          where

import Engine.OpticClass
import Engine.TLL


-- TODO Unify the diagnostics and reduce clutter here

--------------------------------------------------------
-- Diagnosticinformation and processesing of information
-- for standard game-theoretic analysis

-- Defining the necessary types for outputting information of a BayesianGame
data DiagnosticInfoBayesian x y = DiagnosticInfoBayesian {
  equilibrium     :: Bool,
  player          :: String,
  optimalMove     :: y,
  strategy        :: Stochastic y,
  optimalPayoff   :: Double,
  payoff          :: Double,
  state           :: x,
  unobservedState :: String}
  deriving (Show, Eq)



-- diagnostic information for pure games
data DiagnosticInfoPure x y = DiagnosticInfoPure {
  equilibriumP     :: Bool,
  playerP          :: String,
  optimalMoveP     :: y,
  strategyP        :: y,
  optimalPayoffP   :: Double,
  payoffP          :: Double,
  stateP           :: x}




-- prepare string information for Bayesian game
showDiagnosticInfo :: (Show y, Ord y, Show x) => DiagnosticInfoBayesian x y -> String
showDiagnosticInfo info =  
     "\n"    ++ "Player: " ++ player info
     ++ "\n" ++ "Optimal move: " ++ (show $ optimalMove info)
     ++ "\n" ++ "Current Strategy: " ++ (show $ strategy info)
     ++ "\n" ++ "Optimal Payoff: " ++ (show $ optimalPayoff info)
     ++ "\n" ++ "Current Payoff: " ++ (show $ payoff info)
     ++ "\n" ++ "Observable State: " ++ (show $ state info)
     ++ "\n" ++ "Unobservable State: " ++ (show $ unobservedState info)

-- prepare string information for pure game
showDiagnosticInfoPure :: (Show y, Ord y, Show x) => DiagnosticInfoPure x y -> String
showDiagnosticInfoPure info =  
     "\n"    ++ "Player: " ++ playerP info
     ++ "\n" ++ "Optimal move: " ++ (show $ optimalMoveP info)
     ++ "\n" ++ "Current Strategy: " ++ (show $ strategyP info)
     ++ "\n" ++ "Optimal Payoff: " ++ (show $ optimalPayoffP info)
     ++ "\n" ++ "Current Payoff: " ++ (show $ payoffP info)
     ++ "\n" ++ "Observable State: " ++ (show $ stateP info)



-- output string information for a subgame expressions containing information from several players - bayesian 
showDiagnosticInfoL :: (Show y, Ord y, Show x) => [DiagnosticInfoBayesian x y] -> String
showDiagnosticInfoL [] = "\n --No more information--"
showDiagnosticInfoL (x:xs)  = showDiagnosticInfo x ++ "\n --other game-- " ++ showDiagnosticInfoL xs 

-- output string information for a subgame expressions containing information from several players - pure
showDiagnosticInfoPL :: (Show y, Ord y, Show x) => [DiagnosticInfoPure x y] -> String
showDiagnosticInfoPL [] = "\n --No more information--"
showDiagnosticInfoPL (x:xs)  = showDiagnosticInfoPure x ++ "\n --other game-- " ++ showDiagnosticInfoPL xs 

-- checks equilibrium and if not outputs relevant deviations
checkEqL :: (Show y, Ord y, Show x) => [DiagnosticInfoBayesian x y] -> String
checkEqL ls = let xs = fmap equilibrium ls
                  ys = filter (\x -> equilibrium x == False) ls
                  isEq = and xs
                  in if isEq == True then "\n Strategies are in equilibrium"
                                      else "\n Strategies are NOT in equilibrium. Consider the following profitable deviations: \n"  ++ showDiagnosticInfoL ys

-- checks equilibrium and if not outputs relevant deviations
checkEqPL :: (Show y, Ord y, Show x) => [DiagnosticInfoPure x y] -> String
checkEqPL ls = let xs = fmap equilibriumP ls
                   ys = filter (\x -> equilibriumP x == False) ls
                   isEq = and xs
                   in if isEq == True then "\n Strategies are in equilibrium"
                                      else "\n Strategies are NOT in equilibrium. Consider the following profitable deviations: \n"  ++ showDiagnosticInfoPL ys



----------------------------------------------------------
-- providing the relevant functionality at the type level
data ShowDiagnosticOutput = ShowDiagnosticOutput

instance (Show y, Ord y, Show x) => Apply ShowDiagnosticOutput [DiagnosticInfoBayesian x y] String where
  apply _ x = showDiagnosticInfoL x

instance (Show y, Ord y, Show x) => Apply ShowDiagnosticOutput [DiagnosticInfoPure x y] String where
  apply _ x = showDiagnosticInfoPL x



data PrintIsEq = PrintIsEq
instance (Show y, Ord y, Show x) => Apply PrintIsEq [DiagnosticInfoBayesian x y] String where
  apply _ x = checkEqL x

instance (Show y, Ord y, Show x) => Apply PrintIsEq [DiagnosticInfoPure x y] String where
  apply _ x = checkEqPL x



data PrintOutput = PrintOutput
instance (Show y, Ord y, Show x) => Apply PrintOutput [DiagnosticInfoBayesian x y] String where
  apply _ x = showDiagnosticInfoL x

instance (Show y, Ord y, Show x) => Apply PrintOutput [DiagnosticInfoPure x y] String where
  apply _ x = showDiagnosticInfoPL x



data Concat = Concat
instance Apply Concat String (String -> String) where
  apply _ x = \y -> x ++ "\n NEWGAME: \n" ++ y



---------------------
-- main functionality

-- all information for all players
generateOutput :: forall xs.
               ( MapL   PrintOutput xs     (ConstMap String xs)
               , FoldrL Concat String (ConstMap String xs)
               ) => List xs -> String
generateOutput hlist =
  "----Analytics begin----" ++ (foldrL Concat "" $ mapL @_ @_ @(ConstMap String xs) PrintOutput hlist) ++ "----Analytics end----\n"

-- output equilibrium relevant information
generateIsEq :: forall xs.
               ( MapL   PrintIsEq xs     (ConstMap String xs)
               , FoldrL Concat String (ConstMap String xs)
               ) => List xs -> String
generateIsEq hlist =
  "----Analytics begin----" ++ (foldrL Concat "" $ mapL @_ @_ @(ConstMap String xs) PrintIsEq hlist) ++ "----Analytics end----\n"


