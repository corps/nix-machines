module App where

import Prelude hiding ((/))

import App.Router as AppRouter

import Effect (Effect)
import React.Basic.DOM as R
import Concur.Core.Types (Widget)
import Concur.React (HTML)
import App.Router (mkRouter)
import Concur.React.DOM as D
import App.Routes (Page(..), Route(..))
import Data.Tuple (Tuple(Tuple))
import Concur.Core.FRP (display, dyn)
import Web.Router.Internal.Types (RouterInterface)
import App.Components (mkContainer)
import Effect.Class (liftEffect)
import Control.Monad.Rec.Class (forever)

newGame :: forall a. RouterInterface Page -> Widget HTML a
newGame router = do
    forever do
        container <- liftEffect mkContainer
        void $ container $ D.h2' [D.text "New Game"]
--        liftEffect $ router.navigate $ NewGame

mkHtmlApp :: forall a. Effect (Widget HTML a)
mkHtmlApp = do
    Tuple router routes <- mkRouter $ Page NewGame
    void router.initialize
    pure $ dyn do
        route <- routes
        case route of
            Page NewGame -> display $ newGame router
            Page (PlayGame _) -> display $ D.text "loading"
            NotFound -> display $ D.text "Not Found"
