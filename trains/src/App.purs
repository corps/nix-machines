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
import Data.Tuple (Tuple(Tuple))
import Concur.Core.FRP (Signal, display, dyn, loopW)
import Web.Router.Internal.Types (RouterInterface)
import Data.Monoid (mempty)
import Concur.React.Props (unsafeTargetValue)
import App.Components (primeReactApp, button)

type NewGameFormState = { numberPlayers :: String }

newGame :: RouterInterface Page -> Signal HTML NewGameFormState
newGame router =
    loopW mempty formView
    where
    formView :: NewGameFormState -> Widget HTML NewGameFormState
    formView state = do
        state <- D.div'
            [ D.h2' [D.text "New Game"]
            , D.label' $ [D.text "Players"]
            , D.input [P._type "number", unsafeTargetValue >>> { numberPlayers: _ } <$> P.onChange]
            , button [] [D.text "Start New Game"]
            ]
        pure state
--        liftEffect $ router.navigate $ NewGame

mkHtmlApp :: forall a. Effect (Widget HTML a)
mkHtmlApp = do
    Tuple router routes <- mkRouter $ Page NewGame
    void router.initialize
    pure $ primeReactApp [] [dyn do
        route <- routes
        case route of
            Page NewGame -> void $ newGame router
            Page (PlayGame _) -> display $ D.text "loading"
            NotFound -> display $ D.text "Not Found"
    ]
