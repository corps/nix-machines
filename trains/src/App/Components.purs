module App.Components where

import Prelude
import Data.Newtype (class Newtype)
import Web.DOM.NonElementParentNode (getElementById)

import Web.DOM.Internal.Types (Element)
import Effect (Effect)
import Data.Maybe (Maybe(..), fromMaybe)
import Web.HTML (window)
import Web.HTML.Window (document)
import Web.HTML.HTMLDocument (toNonElementParentNode)
import Effect.Exception (throw)
import Web.DOM.Element (getAttribute)
import React.Basic (JSX, ReactComponent)
import React (ReactElement)
import Concur.Core.Types (Widget)
import Concur.React (HTML)
import Concur.React.DOM as DOM
import Concur.React.Props (className)

type Container a = Widget HTML a -> Widget HTML a

attrFromEle :: String -> String -> Effect String
attrFromEle attr eid = do
    d <- toNonElementParentNode <$> (window >>= document)
    ele <- getElementById eid d
    case ele of
        Nothing -> throw $ "Could not find element #" <> eid
        Just e -> fromMaybe "" <$> getAttribute attr e

mkContainer :: forall a. Effect (Container a)
mkContainer = do
    cls <- attrFromEle "class" "container"
    pure $ wrapper cls
    where
        wrapper :: String -> Widget HTML a -> Widget HTML a
        wrapper cls inner = DOM.div [className cls] [inner]
