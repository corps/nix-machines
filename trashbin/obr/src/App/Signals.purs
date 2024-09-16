module App.Signal where

import Prelude
import Data.Function (($))
import Control.Applicative (pure)
import Effect.Aff (Aff, finally, launchAff_)
import Effect.Aff.AVar (empty, put, take) as AVar
import Effect.AVar (AVar)
import Effect.Unsafe (unsafePerformEffect)
import Data.Unit (unit)
import Effect (Effect)
import Effect.Class (liftEffect)
import Concur.Core.FRP (Signal, fireOnce, loopW)
import Data.Maybe (Maybe(..), fromMaybe)
import Effect.Aff.Class (liftAff)
import Data.Either (Either(..))
import Data.Foldable (oneOf)
import Data.Tuple (Tuple(..))
import Effect.Console (log)


handleAff :: forall a b. Monoid b => Array (Maybe (Aff a)) -> Signal b (Either Boolean a)
handleAff group = do
    case oneOf group of
        Just aff -> do
            maybeResult <- fireOnce $ liftAff aff
            pure $ fromMaybe (Left true) $ Right <$> maybeResult
        Nothing -> pure $ Left false

mkCallback :: forall a. AVar a -> (a -> Unit)
mkCallback avar a = unsafePerformEffect $ launchAff_ $ do
    liftEffect $ log "putting..."
    AVar.put a avar
    liftEffect $ log "put"


awaitNext :: forall a. ((a -> Unit) -> (Unit -> Unit)) -> Aff a
awaitNext subscriber = do
  var <- AVar.empty
  let
    cb = mkCallback var
    cancel = subscriber cb
    finalize :: Aff Unit
    finalize = do
        liftEffect $ log "finalize"
        liftEffect $ pure $ cancel unit
  finalize `finally` do
    liftEffect $ log "taking"
    result <- AVar.take var
    liftEffect $ log "take"
    pure result

awaitAff :: forall a b. Monoid b => Aff a -> Signal b (Maybe a)
awaitAff aff = fireOnce $ liftAff aff

maybeContinueAff :: forall a b. Monoid b => Maybe (Aff a) -> Signal b (Maybe a)
maybeContinueAff aff = fromMaybe (pure Nothing) (aff <#> awaitAff)

asReady :: Maybe Boolean -> Maybe Unit
asReady r = case r of
                Just true -> Just unit
                _ -> Nothing

asUnready :: Maybe Boolean -> Maybe Unit
asUnready r = case r of
                Just true -> Nothing
                _ -> Just unit

maybeRepeatAff :: forall a b. Monoid b => Maybe (Aff a) -> Signal b (Maybe a)
maybeRepeatAff maybeAff = fromMaybe (pure Nothing) (maybeAff <#> \aff -> loopW Nothing \_ -> Just <$> liftAff aff)

type Loading a = Tuple Boolean a
handleLoading :: forall a b. Monoid b => Loading a -> Aff a -> Aff a -> Signal b (Loading a)
handleLoading state curAff nextAff = loopW state \state' -> do
    case state' of
        Tuple false _ -> do
            liftEffect $ log "start cur loading"
            cur <- liftAff curAff
            liftEffect $ log "done loading"
            pure $ Tuple true cur
        Tuple true _ -> do
            liftEffect $ log "start next loading"
            cur <- liftAff nextAff
            liftEffect $ log "done loading"
            pure $ Tuple false cur
