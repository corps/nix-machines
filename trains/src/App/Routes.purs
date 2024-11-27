module App.Routes
  ( Page(..)
  , Route(..)
  , parseRoute
  , printRoute
  ) where

import Prelude hiding ((/))

import Data.Either (Either)
import Data.Generic.Rep (class Generic)
import Routing.Duplex (RouteDuplex', default, end, parse, print, root, segment)
import Routing.Duplex.Generic (noArgs, sum)
import Routing.Duplex.Generic.Syntax ((/))
import Routing.Duplex.Parser (RouteError)

data Route
  = Page Page
  | NotFound

data Page
  = NewGame
  | PlayGame String

derive instance Generic Route _
derive instance Generic Page _

routes :: RouteDuplex' Route
routes =
  default NotFound $
    sum
      { "Page": pages
      , "NotFound": "404" / noArgs
      }

pages :: RouteDuplex' Page
pages =
  root $ end $ sum
    { "NewGame": noArgs
    , "PlayGame": "game" / segment
    }

parseRoute :: String -> Either RouteError Route
parseRoute = parse routes

printRoute :: Page -> String
printRoute = print pages
