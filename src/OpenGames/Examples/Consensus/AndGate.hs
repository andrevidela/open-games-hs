{-# LANGUAGE TemplateHaskell #-}

module OpenGames.Examples.Consensus.AndGate where

import Numeric.Probability.Distribution (certainly, uniform, fromFreqs)

import OpenGames.Preprocessor.THSyntax
import OpenGames.Engine.OpenGamesClass
import OpenGames.Engine.StatefulBayesian hiding (decision, roleDecision, dependentDecision)
import OpenGames.Engine.DependentDecision

import OpenGames.Examples.Consensus.DepositGame (depositStagePlayer, playingStagePlayer, attackerPayoff)

obfuscateAndGate :: [Bool] -> Bool
obfuscateAndGate = and

payoffAndGate :: Double -> Double -> [Double] -> Bool -> [Double]
payoffAndGate penalty reward deposits True
  | (sumDeposits > 0) = [deposit*reward/sumDeposits | deposit <- deposits]
  | (sumDeposits == 0) = [0 | _ <- deposits]
  where sumDeposits = sum deposits
payoffAndGate penalty reward deposits False
  = [-penalty*deposit | deposit <- deposits]
    {-
generateGame "andGateGame" ["numPlayers", "reward", "costOfCapital", "minBribe", "maxBribe", "incrementBribe", "maxSuccessfulAttackPayoff", "attackerProbability", "penalty", "minDeposit", "maxDeposit", "incrementDeposit", "epsilon"] $ block [] []
  [line [ [| replicate numPlayers costOfCapital |] ] ["discard1"] [| population [depositStagePlayer ("Player " ++ show n) minDeposit maxDeposit incrementDeposit epsilon | n <- [1 .. numPlayers]] |] ["deposits"] [ [| replicate numPlayers () |] ],
   line [] [] [| nature (fromFreqs [(0, 1 - attackerProbability), (maxSuccessfulAttackPayoff, attackerProbability)]) |] ["successfulAttackPayoff"] [],
   line [ [| deposits |], [| successfulAttackPayoff |] ] [] [| dependentDecision "Attacker" (const [minBribe, minBribe+incrementBribe .. maxBribe]) |] ["bribe"] [ [| attackerPayoff bribesAccepted bribe successfulAttackPayoff |] ],
   line [ [| replicate numPlayers (deposits, bribe) |] ] ["discard2"] [| population [playingStagePlayer ("Player " ++ show n) [True, False] | n <- [1 .. numPlayers]] |] ["moves"] [ [| zip (payoffAndGate penalty reward deposits (obfuscateAndGate moves)) bribesAccepted |] ],
   line [ [| moves |] ] [] [| fromFunctions (map not) id |] ["bribesAccepted"] []]
  [] []
  -}
