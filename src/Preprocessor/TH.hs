{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE NamedFieldPuns #-}

module Preprocessor.TH (Variables(..)
                       , Expressions(..)
                       , FreeOpenGame(..)
                       , FunctionExpression(..)
                       , interpretOpenGame
                       , interpretFunction
                       ) where

import Language.Haskell.TH
import Language.Haskell.TH.Syntax
import Preprocessor.Types



combinePats :: [Pat] -> Pat
combinePats [x] = x
combinePats xs = TupP xs

apply :: Exp -> [Exp] -> Exp
apply fn [] = fn
apply fn (x : xs) = apply (AppE fn x) xs

patToExp :: Pat -> Exp
patToExp (VarP e) = VarE e
patToExp (TupP e) = TupE (map (patToExp) e)
patToExp (LitP e) = LitE e
patToExp (ListP e) = ListE (fmap patToExp e)
patToExp (ConP n e) = apply (VarE n) (fmap patToExp e)

interpretFunction :: FunctionExpression Pat Exp-> Q Exp
interpretFunction Identity = [| id |]
interpretFunction Copy = [| \x -> (x, x) |]
interpretFunction (Lambda (Variables {vars}) (Expressions {exps})) =
  pure $ LamE (pure $ TupP vars) (TupE exps)
interpretFunction (CopyLambda (Variables { vars }) (Expressions { exps })) =
  pure $ LamE (pure $ TupP vars) (TupE [TupE $ map patToExp vars, TupE exps])
interpretFunction (Multiplex (Variables { vars }) (Variables { vars = vars' })) =
  pure $ LamE (pure $ TupP [combinePats vars, combinePats vars']) (TupE $ map patToExp (vars ++ vars'))
interpretFunction (Curry f) = [| curry $(interpretFunction f)|]


interpretOpenGame :: FreeOpenGame Pat Exp-> Q Exp
interpretOpenGame (Atom n) = pure n
interpretOpenGame (Lens f1 f2) = [| fromLens $(interpretFunction f1) $(interpretFunction f2) |]
interpretOpenGame (Function f1 f2) = [| fromFunctions $(interpretFunction f1) $(interpretFunction f2)|]
interpretOpenGame Counit = [| counit |]
interpretOpenGame (Sequential g1 g2) = [| $(interpretOpenGame g1) >>> $(interpretOpenGame g2)|]
interpretOpenGame (Simultaneous g1 g2) = [| $(interpretOpenGame g1) &&& $(interpretOpenGame g2)|]
