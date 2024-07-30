module App.Router where

import Prelude

import App.Routes (Page, Route, parseRoute, printRoute)
import Data.Newtype (class Newtype)
import Data.Tuple.Nested ((/\))
import Effect (Effect)
import Effect.Ref as Ref
import React.Basic.Hooks (JSX, UseContext)
import React.Basic.Hooks as React
import Web.Router as Router
import Web.Router.PushState as PushState
import Web.Router.Internal.Control (Resolved, RouterM, Routing)
import Data.Maybe (Maybe)
import Concur.Core.FRP (Signal, step)
import Effect.Exception (Error)
import Data.Either (Either(..))
import Effect.Aff (Aff, Canceler(..), makeAff)
import Effect.Ref (Ref)
import Effect.Class (liftEffect)
import Data.Monoid (mempty)
import Web.Router.Internal.Types (RouterEvent(..), RouterInterface)
import Effect.Aff.Class (liftAff)
import Data.Tuple (Tuple)

type AffCb a = Either Error a -> Effect Unit
type RoutingAction = Router.RouterEvent Route

mkRouter :: forall a. Monoid a => Route -> Effect (Tuple (RouterInterface Page) (Signal a Route))
mkRouter dfRoute = do
  onResolvedRoute <- Ref.new mempty
  let
    onNavigation :: Maybe Route -> Route -> RouterM Route Page Routing Resolved Unit
    onNavigation _ _ = Router.continue
    onEvent :: RoutingAction -> Effect Unit
    onEvent event = case event of
        Routing _ _ -> pure unit
        Resolved _ route -> join $ Ref.read onResolvedRoute <@> Right route

  driver <- PushState.mkInterface parseRoute printRoute
  router <- Router.mkInterface onNavigation onEvent driver

  pure $ router /\ (buildSignal (buildActionAff onResolvedRoute) $ dfRoute)

  where
    buildActionAff :: Ref (AffCb Route) -> Aff Route
    buildActionAff cbRef = makeAff go
        where
        go :: AffCb Route -> Effect Canceler
        go cb = do
            Ref.write cb cbRef
            pure $ Canceler $ \_ -> liftEffect $ Ref.write mempty cbRef

    buildSignal :: Aff Route -> Route -> Signal a Route
    buildSignal nextAction action = step action do
        a' <- liftAff nextAction
        pure $ buildSignal nextAction a'
