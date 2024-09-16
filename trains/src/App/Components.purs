module App.Components where

import Prelude
import Concur.React.DOM as D
import React (ReactClass, unsafeCreateElement)
import Concur.React.DOM (el', El)
import React.DOM.Props (unsafeFromPropsArray)

foreign import _primeReactApp :: forall a. ReactClass a
foreign import _primeButton :: forall a. ReactClass a

primeReactApp :: El
primeReactApp = el' (unsafeCreateElement _primeReactApp <<< unsafeFromPropsArray)

button :: El
button = el' (unsafeCreateElement _primeButton <<< unsafeFromPropsArray)
