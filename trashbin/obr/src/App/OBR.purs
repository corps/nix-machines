module App.OBR where

import Prelude
import Effect (Effect)
import Data.Argonaut.Core (Json)
import Control.Promise (Promise)
import Effect.Aff (Aff, launchAff_)
import Data.Nullable (Nullable)
import Effect.Class (liftEffect)
import Data.Either (Either, fromRight)
import Effect.Exception (Error)
import Effect.Unsafe (unsafePerformEffect)
import Data.Argonaut.Encode.Class (class EncodeJson, encodeJson)
import Effect.Aff.AVar (empty, take, tryPut) as AVar
import Effect.AVar (AVar)
import App.Signal (mkCallback)
import Effect.Uncurried (EffectFn1, EffectFn2, runEffectFn1)
import Data.Tuple (Tuple(..))
import Data.Argonaut.Decode.Class (class DecodeJson, decodeJson)
import Data.Maybe (Maybe, Maybe(Nothing), Maybe(Just))
import Data.Argonaut.Decode.Error (JsonDecodeError)
import Effect.Console (log)

foreign import data Metadata :: Type

type AffCb a = Either Error a -> Effect Unit

type StoredMetadata a = { set :: Metadata -> a -> Metadata, get :: Metadata -> a, getMaybe :: Metadata -> Maybe a, namespace :: String, unset :: Metadata -> Metadata, default :: a }

metadata :: forall a. EncodeJson a => DecodeJson a => String -> a -> StoredMetadata a
metadata key default = { set: set, get: get, getMaybe: getMaybe, namespace: key, unset: unset, default: default }
    where
        set md v = setMetadata md key $ encodeJson v
        get md = fromRight default $ decodeJson $ getMetadata md key
        getMaybe md = fromRight Nothing $ Just <$> (decodeJson $ getMetadata md key :: Either JsonDecodeError a)
        unset :: Metadata -> Metadata
        unset md = unsetMetadata md key

type MessageEvent = { "data" :: Json, connectionId :: String }
type Player = { id :: String, connectionId :: String, role :: String, select :: Nullable (Array String), name :: String, color :: String, syncView :: Boolean, metadata :: Metadata }
type Item =
  { id :: String
  , "type" :: String
  , name :: String
  , visible :: Boolean
  , attachedTo :: Nullable String
  , metadata :: Metadata
  , layer :: String
  }

type KeyFilter =
  { key :: String
  , value :: Json
  }

type ContextMenuIcon =
  { icon :: String
  , label :: String
  , filter :: { roles :: Array String, some :: Array KeyFilter, every :: Array KeyFilter }
  }

type ContextMenuItem r =
  { id :: String
  , icons :: Array ContextMenuIcon
  | r
  }

type ClickableContextMenuItem =
  ( onClick :: ContextMenuContext -> Unit
  )

type ContextMenuEmbed =
  { url :: String
  , height :: Int
  }

type ContextMenuContext =
  { items :: Array Item
  }

type EmbedableContextMenuItem =
  ( embed :: ContextMenuEmbed
  )

type Observable a = (a -> Unit) -> (Unit -> Unit)
foreign import data Mutation :: Type -> Type
foreign import mutation :: forall a. (a -> a) -> Mutation a

type OBR =
    { isReady ::Boolean
    , onReady :: EffectFn1 (Unit -> Unit) Unit
    , scene ::
        { isReady :: Effect (Promise Boolean)
        , onReadyChange :: Observable Boolean
        , getMetadata :: Effect (Promise Metadata)
        , onMetadataChange :: Observable Metadata
        , setMetadata :: Metadata -> Promise Unit
        , items ::
            { onChange :: Observable (Array Item)
            , getItems :: Effect (Promise (Array Item))
            , updateItems :: EffectFn2 (Array Item) (Mutation (Array Item)) (Promise Unit)
            }
        }
    , broadcast ::
        { sendMessage :: EffectFn2 String Json (Promise Unit)
        , onMessage :: EffectFn2 String (Json -> Unit) (Unit -> Unit)
        }
    , player ::
        { id :: String
        , getMetadata :: Effect (Promise Metadata)
        , select :: EffectFn2 (Array Item) Boolean (Promise Unit)
        }
    , contextMenu ::
        { create :: forall r. ContextMenuItem r -> Promise Unit
        }
    }

foreign import obr :: OBR

foreign import getMetadata :: Metadata -> String -> Json
foreign import setMetadata :: Metadata -> String -> Json -> Metadata
foreign import unsetMetadata :: Metadata -> String -> Metadata
foreign import unsetMetadataKeyFilter :: String -> KeyFilter
foreign import setMetadataKeyFilter :: String -> KeyFilter
foreign import ready :: Promise Unit
foreign import emptyMetadata :: Metadata
foreign import _undefined :: forall a. a

undefined = _undefined


filterCharacters :: Array KeyFilter
filterCharacters =
  [ { key: "type", value: encodeJson "IMAGE" }
  , { key: "layer", value: encodeJson "CHARACTER" }
  ]

mkClickableContextMenuItem :: ContextMenuItem () -> Aff (Tuple (ContextMenuItem ClickableContextMenuItem) (AVar ContextMenuContext))
mkClickableContextMenuItem baseRecord = do
    var <- AVar.empty
    let
        rec = { id: baseRecord.id, icons: baseRecord.icons, onClick: \c -> unsafePerformEffect $ launchAff_ $ void $ AVar.tryPut c var }
    pure $ Tuple rec var
