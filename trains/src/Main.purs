module Main where

import Prelude
import App as App
import App.Router as AppRouter
import Effect (Effect)
import Effect.Exception as Exception
import React.Basic.DOM as ReactDOM
import Concur.React.Run (runWidgetInDom)
import App (mkHtmlApp)

main :: Effect Unit
main = do
    htmlApp <- mkHtmlApp
    runWidgetInDom "app" htmlApp
