module App.Components where

import Prelude
import Prim.Row as Row
import Concur.React.DOM as D
import Concur.React.Props as P
import React (ReactClass, unsafeCreateElement)
import Concur.React.DOM (El, el')
import React.DOM.Props (unsafeFromPropsArray, unsafeMkProps)
import Data.Newtype (class Newtype, unwrap)
import Data.Generic.Rep (class Generic)
import Data.Symbol (class IsSymbol)
import App.ClassNames as C
import Concur.Core.Types (Widget)
import Concur.React (HTML)
import Concur.React.Props (ReactProps, className, unsafeMkProp, unsafeTargetValue)
import Concur.Core.FRP (Signal, demand, demandLoop, display, dyn, fireOnce, hold, loopW)
import App.ClassNames (class AsClassName, Col(Col), Col(ColFixed), Display(Flex), Field(Field), FlexDirection(FlexColumn, FlexRow), Formgrid(Formgrid), Grid(Grid), Maxed(WFull), asClassName)
import Data.Functor (class Functor)
import React.SyntheticEvent (SyntheticEvent, SyntheticEvent_)
import Unsafe.Coerce (unsafeCoerce)
import Control.Bind (class Bind)
import Concur.Core.Props (Props(..))
import Data.Array (foldr)
import Data.Either (Either(..))
import Control.ShiftMap (class ShiftMap)
import Control.MultiAlternative (class MultiAlternative)
import Concur.Core.IsWidget (class IsWidget)
import Data.Maybe (Maybe(..), fromMaybe)
import Effect.Aff (Aff)
import Data.Nullable (notNull, null)
import Effect.Uncurried (mkEffectFn1)
import Effect (Effect)

foreign import _primeReactApp :: forall a. ReactClass a
foreign import _primeButton :: forall a. ReactClass a
foreign import _primeInputText :: forall a. ReactClass a
foreign import _primeDropdown :: forall a. ReactClass a

type DropdownOption a = { label :: String, value :: a }

primeReactApp :: El
primeReactApp = el' (unsafeCreateElement _primeReactApp <<< unsafeFromPropsArray)

_button :: El
_button = el' (unsafeCreateElement _primeButton <<< unsafeFromPropsArray)

_inputText :: El
_inputText = el' (unsafeCreateElement _primeInputText <<< unsafeFromPropsArray)

_dropdown :: El
_dropdown = el' (unsafeCreateElement _primeDropdown <<< unsafeFromPropsArray)

type PropArray a = Array (ReactProps a)
type SignalLoop a = a -> Signal HTML a

contain :: forall a. (Array (ReactProps a) -> Array (Widget HTML a) -> Widget HTML a) -> Signal HTML Unit -> Signal HTML Unit
contain widget signal = loopW unit \_ -> void $ widget [] [ dyn $ signal ]

thread :: forall a. (Array (ReactProps a) -> Array (Widget HTML a) -> Widget HTML a) -> Signal HTML (Maybe a) -> Signal HTML (Maybe a)
thread widget signal = loopW Nothing \_ -> Just <$> widget [] [ demand signal ]

runLocal :: forall a r. (Array (ReactProps (Maybe r)) -> Array (Widget HTML (Maybe r)) -> Widget HTML (Maybe r)) -> a -> (a -> Signal HTML (Either a r)) -> Signal HTML (Maybe r)
runLocal widget state f = loopW Nothing \_ -> widget [] [ Just <$> demandLoop state f ]

data SubmissionKind = OnBlur | OnKeyEnter | OnChange
type Submission a = { kind :: SubmissionKind, event :: SyntheticEvent, value :: Unit -> a }
type DropdownEvent a = { value :: a }

dropdownOnChange :: forall a. ReactProps (DropdownEvent a)
dropdownOnChange = Handler prop
    where
        prop f = unsafeMkProps "onChange" (mkEffectFn1 f)

submitOnChange :: ReactProps (Submission String)
submitOnChange = (\e -> { event: unsafeCoerce e, value: \_ -> unsafeTargetValue e, kind: OnChange }) <$> P.onChange

submitOnBlur :: ReactProps (Submission String)
submitOnBlur = (\e -> { event: unsafeCoerce e, value: \_ -> unsafeTargetValue e, kind: OnBlur }) <$> P.onBlur

submitOnKeyEnter :: ReactProps (Submission String)
submitOnKeyEnter = (\e -> { event: unsafeCoerce e, value: \_ -> unsafeTargetValue e, kind: OnKeyEnter }) <$> P.onKeyEnter

inputText :: Boolean -> PropArray (Submission String) -> SignalLoop String
inputText controlled = c `addClass` WFull
  where
  c props s = loopW s \s' -> do
    v <- _inputText (props <> [ if controlled then P.value s' else P.defaultValue s' ]) []
    pure $ v.value unit

toDropdownOption :: forall a. Show a => a -> DropdownOption a
toDropdownOption v = { label: show v, value: v }


dropdown :: forall a. Show a => PropArray (DropdownEvent a) -> Boolean -> Array a -> SignalLoop (Maybe a)
dropdown = c `addClass` WFull
    where
    c props controlled options s = loopW s \s' -> do
        let
            v :: String
            v = unsafeCoerce $ fromMaybe null $ notNull <$> s'
            options' :: ReactProps (DropdownEvent a)
            options' = unsafeMkProp "options" $ map toDropdownOption options
        selected <- _dropdown (props <> [ options', dropdownOnChange, if controlled then P.value v else P.defaultValue v ]) []
        pure $ Just $ selected.value

button :: forall a. PropArray a -> String -> Maybe a -> Signal HTML (Maybe a)
button props l onClick = hold Nothing $ Just <$> _button props' []
    where
        props' :: PropArray a
        props' = case onClick of
            Nothing -> props <> [ P.label l, P.disabled true ]
            Just onClick' -> props <> [ P.label l, onClick' <$ P.onClick ]

displayLabel :: String -> Signal HTML Unit
displayLabel l = do
  display $ D.label [] [ D.text l ]

displayError :: forall a. Either String a -> Signal HTML Unit
displayError (Left l) = do display $ D.small [] [ D.text l ]
displayError _ = pure unit

foreign import _addClassName :: forall p. String -> p -> p
foreign import _isClassName :: forall p. p -> Boolean

addClass :: forall p a c. AsClassName c => (PropArray p -> a) -> c -> (PropArray p -> a)
addClass c v = \props -> c $
  if foldr (\p b -> isClassName' p || b) false props then map addClass' props
  else props <> [ P.className $ unwrap $ asClassName v ]
  where
  addClass' :: ReactProps p -> ReactProps p
  addClass' p = case p of
    PrimProp r -> PrimProp $ _addClassName (unwrap $ asClassName v) r
    _ -> p

  isClassName' :: ReactProps p -> Boolean
  isClassName' (PrimProp r) = _isClassName r
  isClassName' _ = false

addProps :: forall p a. (PropArray p -> a) -> ReactProps p -> (PropArray p -> a)
addProps c p = \props -> c $ props <> [ p ]

setStyle :: forall p a r. (PropArray p -> a) -> { | r } -> (PropArray p -> a)
setStyle c s = c `addProps` P.style s

div :: El
div = D.div

pre :: El
pre = D.pre

label :: El
label = D.label

field :: El
field = div `addClass` Field

fieldGrid :: El
fieldGrid = field `addClass` Grid

colField :: El
colField = field `addClass` Col

formGrid :: El
formGrid = div `addClass` Grid `addClass` Formgrid

rows :: El
rows = div `addClass` Flex `addClass` FlexColumn

cols :: El
cols = div `addClass` Flex `addClass` FlexRow

colLabel :: String -> Signal HTML Unit
colLabel s = display $ (label `addClass` ColFixed) [] [D.text s]
