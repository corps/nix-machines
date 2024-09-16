module App where

import Prelude hiding ((/))

import App.Router as AppRouter

import Effect (Effect)
import React.Basic.DOM as R
import Concur.Core.Types (Widget)
import Concur.React (HTML)
import App.Router (mkRouter)
import Concur.React.DOM as D
import Concur.React.Props as P
import App.Routes (Page(..), Route(..))
import Data.Tuple (Tuple(Tuple), fst, snd)
import Concur.Core.FRP (Signal, display, dyn)
import Web.Router.Internal.Types (RouterInterface)
import App.Components (button, colField, colLabel, dropdown, fieldGrid, formGrid, primeReactApp, runLocal, setStyle, thread)
import App.Components as C
import Data.Either (Either(..))
import Data.Maybe (Maybe(..), fromMaybe, isNothing)
import Concur.React.DOM (El)
import Control.ShiftMap (class ShiftMap)
import Control.MultiAlternative (class MultiAlternative)
import App.OBR (Item, Metadata, Mutation, StoredMetadata, emptyMetadata, filterCharacters, metadata, mkClickableContextMenuItem, mutation, obr, ready, setMetadataKeyFilter, unsetMetadataKeyFilter)
import Data.Map.Internal (Map, findMax, fromFoldable, insert, keys, lookup, lookupGT, lookupLT, toUnfoldable)
import Data.Array (all, difference)
import Effect.Random (randomInt)
import Effect.Aff (Aff)
import Effect.Class (liftEffect)
import Data.Map (empty, singleton) as Map
import Data.Traversable (traverse)
import Data.List.Types (List)
import Data.Foldable (foldMap)
import Effect.Uncurried (runEffectFn2)
import Control.Promise (Promise, toAff, toAffE)
import App.Signal (awaitAff, awaitNext, handleAff, handleLoading, maybeContinueAff, maybeRepeatAff)
import Effect.Aff.AVar (take) as AVar
import Effect.Console (log)

import Debug (spy)
import Effect.Aff.Class (liftAff)

popOverContainer :: El
popOverContainer = formGrid `setStyle` { width: "400px" }

type TrackedItemData = { group :: Int }
type GroupRoundData = { roll :: Int, election :: Maybe Int }
type TrackedGroupData = Map Int GroupRoundData

trackedItemMetadata :: StoredMetadata TrackedItemData
trackedItemMetadata = metadata "com.github.corps/trackedItem" { group: 0}

groupDataMetadata :: StoredMetadata TrackedGroupData
groupDataMetadata = metadata "come.github.corps/groupData" Map.empty

asGroup :: TrackedGroupData -> Item -> Map (Tuple Int GroupRoundData) (Array (Tuple Item TrackedItemData))
asGroup groupData item =  fromMaybe Map.empty do
    id <- trackedItemMetadata.getMaybe item.metadata
    group <- lookup id.group groupData
    pure $ Map.singleton (Tuple id.group group) $ [Tuple item id]

prevGroup :: TrackedItemData -> TrackedGroupData -> Maybe Int
prevGroup itemData groupData = map _.key $ lookupLT itemData.group groupData

nextGroup :: TrackedItemData -> TrackedGroupData -> Maybe Int
nextGroup itemData groupData = map _.key $ lookupGT itemData.group groupData

newGroup :: TrackedGroupData -> Effect (Tuple Int GroupRoundData)
newGroup groupData = do
  let
    groupId = fromMaybe 0 $ do
      curMax <- findMax groupData
      pure $ curMax.key + 1
  newRound groupId

newRound :: Int -> Effect (Tuple Int GroupRoundData)
newRound c = do
  roll <- randomInt 1 20
  pure $ Tuple c { roll: roll, election: Nothing }

ensureNextGroup :: Maybe Int -> Aff Int
ensureNextGroup (Just nextGroup) = pure nextGroup
ensureNextGroup Nothing = do
  fst <$> updateGroupData \groupData -> do
    Tuple nextGroupId roundData <- liftEffect $ newGroup groupData
    pure $ Tuple nextGroupId $ insert nextGroupId roundData groupData

changeGroup :: Item -> TrackedItemData -> Int -> Aff Int
changeGroup item itemData groupId = do
    join $ map toAff $ liftEffect $ runEffectFn2 obr.scene.items.updateItems [item] $ mutation $ map \i -> (i { metadata = trackedItemMetadata.set i.metadata $ itemData { group = groupId } })
    pure groupId

trackedItemRow :: TrackedGroupData -> Tuple Item TrackedItemData -> Signal HTML (Maybe Unit)
trackedItemRow groupData (Tuple item itemData) = do
  display $ colField [] [ D.b [] [ D.text item.name ] ]
  colField `runLocal` false $ \loading -> do
    a <- button [ P.disabled (loading || isNothing prevGroup') ] "Up" $ prevGroup' <#> (changeGroup item itemData)
    b <- button [ P.disabled loading ] "Down" $ Just $ ensureNextGroup nextGroup' >>= changeGroup item itemData
    map void $ handleAff [a, b]
  where
  prevGroup' = prevGroup itemData groupData
  nextGroup' = nextGroup itemData groupData

remainingRolls :: TrackedGroupData -> Array Int
remainingRolls groupData = difference allElections allRolls
    where
        allElections :: Array Int
        allElections = foldMap (\d -> fromMaybe [] $ pure <$> d.election) groupData
        allRolls :: Array Int
        allRolls = foldMap (\d -> [d.roll]) groupData

updateGroupData :: forall a. (TrackedGroupData -> Aff (Tuple a TrackedGroupData)) ->  Aff (Tuple a TrackedGroupData)
updateGroupData cb = do
    metadata <- join $ toAff <$> liftEffect obr.scene.getMetadata
    Tuple r newGroupData <- cb $ groupDataMetadata.get metadata
    toAff $ obr.scene.setMetadata $ groupDataMetadata.set metadata newGroupData
    pure $ Tuple r newGroupData

trackedGroupRow :: TrackedGroupData -> Tuple (Tuple Int GroupRoundData) (Array (Tuple Item TrackedItemData)) -> Signal HTML (Maybe Unit)
trackedGroupRow groupData (Tuple (Tuple groupId roundData) items) = do
    fieldGrid `runLocal` false $ \loading -> do
        colLabel $ "Group: " <> (show groupId)
        colLabel $ "Roll: " <> (show roundData.roll)
        a <- colField `thread` do
            newElection <- dropdown [P.disabled loading] false allOptions roundData.election
            pure $ newElection $> updateGroupData \gd' -> do
                pure $ Tuple unit $ insert groupId (roundData { election = newElection }) gd'
        map void $ handleAff [a]

    where
        allOptions = fromMaybe [] (pure <$> roundData.election) <> remainingRolls groupData

popOver :: RouterInterface Page -> Signal HTML (Maybe Unit)
popOver _ = do
  let
    items = Tuple false []
    metadata = Tuple false emptyMetadata
    sceneReady = Tuple false false

  popOverContainer `runLocal` { items: items , metadata: metadata, round: 0, sceneReady: sceneReady } $ \{ items, metadata, round, sceneReady } -> do
    sceneReady' <- handleLoading sceneReady (toAffE obr.scene.isReady) (awaitNext obr.scene.onReadyChange)
    metadata' <- handleLoading metadata (toAffE obr.scene.getMetadata) (awaitNext obr.scene.onMetadataChange)
    items' <- handleLoading items (toAffE obr.scene.items.getItems) (awaitNext obr.scene.items.onChange)

    let
      groupData = groupDataMetadata.get $ snd metadata'
      trackedGroupData :: List (Tuple (Tuple Int GroupRoundData) (Array (Tuple Item TrackedItemData)))
      trackedGroupData = toUnfoldable $ foldMap (asGroup groupData) $ snd items'

    round' <- fieldGrid `runLocal` false $ \loading -> do
        colLabel $ "Round: " <> (show round)
        a <- colField `thread` do
            maybeNextRound <- button [] "Reset" (if loading then Nothing else Just (round + 1))
            pure $ maybeNextRound <#> \nextRound -> do
                void $ updateGroupData \gd' -> do
                    newRoundItems <- liftEffect $ traverse newRound $ keys gd'
                    pure $ Tuple unit $ fromFoldable $ newRoundItems
                pure nextRound
        handleAff [a]

    void $ traverse (trackedGroupRow groupData) trackedGroupData

    pure $ Left $ { items: items', metadata: metadata', sceneReady: sceneReady', round: fromMaybe round round' }

foreign import iconSvg :: String

toggleTracking :: Mutation (Array Item)
toggleTracking = mutation \items ->
  if all (\a -> isNothing $ trackedItemMetadata.getMaybe a.metadata) items then
    items <#> \item -> item { metadata = trackedItemMetadata.set item.metadata trackedItemMetadata.default }
  else
    items <#> \item -> item { metadata = trackedItemMetadata.unset item.metadata }

background :: RouterInterface Page -> Signal HTML (Maybe Unit)
background _ = do
  maybeAvar <- awaitAff $ do
    liftEffect $ log "Background loading..."
    Tuple record avar <- mkClickableContextMenuItem
        { id: "com.github.corps/addToTracker"
        , icons:
            [ { icon: iconSvg
              , label: "Add"
              , filter:
                  { roles: [ "GM" ]
                  , every: filterCharacters <>
                      [ unsetMetadataKeyFilter trackedItemMetadata.namespace ]
                  , some: []
                  }
              }
            , { icon: iconSvg
              , label: "Remove"
              , filter:
                  { roles: [ "GM" ]
                  , some: filterCharacters <>
                      [ setMetadataKeyFilter trackedItemMetadata.namespace ]
                  , every: []
                  }
              }
            ]
        }
    toAff $ obr.contextMenu.create record
    liftEffect $ log "Done creating menu record"
    pure $ avar

  maybeClick <- maybeRepeatAff $ maybeAvar <#> AVar.take
  maybeContinueAff $ maybeClick <#> \click -> do
      liftEffect $ log "doing the thing"
      toAffE $ runEffectFn2 obr.scene.items.updateItems click.items toggleTracking
      liftEffect $ log "done"


mkHtmlApp :: forall a. Effect (Widget HTML a)
mkHtmlApp = do
  Tuple router routes <- mkRouter $ Page Popover
  void router.initialize
  pure $ primeReactApp []
    [ do
        liftAff $ toAff ready
        dyn do
            route <- routes
            case route of
              Page Popover -> void $ popOver router
              Page Background -> void $ background router
              NotFound -> display $ D.text "Not Found"
    ]
