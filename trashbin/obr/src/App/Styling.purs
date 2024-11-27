module App.ClassNames where

import Prelude
import React.DOM.Props as RProps
import Data.Newtype (class Newtype, unwrap, wrap)
import Data.Symbol (class IsSymbol, reflectSymbol)
import Data.Generic.Rep (class Generic, Argument(..), Constructor(..), NoArguments, Product(..), Sum(..), from)
import Data.String.Casing (toKebabCase)
import Type.Proxy (Proxy(Proxy))
import Concur.React.Props (ReactProps, className)
import Control.Plus (class Plus)
import Control.Alt (class Alt)

-- https://primeflex.org/texttransform

newtype ClassName = ClassName String

derive instance Newtype ClassName _

instance Semigroup ClassName where
  append a b = wrap $ (unwrap a) <> (unwrap b)

instance Monoid ClassName where
  mempty = ClassName $ ""

class AsClassName a where
  asClassName :: a -> ClassName

class GenericAsClassName a where
  asClassName' :: a -> ClassName

instance IsSymbol name => GenericAsClassName (Constructor name NoArguments) where
  asClassName' _ = ClassName $ toKebabCase $ reflectSymbol (Proxy :: Proxy name)

instance (GenericAsClassName a, GenericAsClassName b) => GenericAsClassName (Sum a b) where
  asClassName' (Inl a) = asClassName' a
  asClassName' (Inr b) = asClassName' b

instance (IsSymbol name, Show a) => GenericAsClassName (Constructor name (Argument a)) where
  asClassName' (Constructor (Argument a)) = ClassName $ (toKebabCase $ reflectSymbol (Proxy :: Proxy name)) <> "-" <> (show a)

instance (IsSymbol name, Show a, Show b) => GenericAsClassName (Constructor name (Product a b)) where
  asClassName' (Constructor (Product a b)) = ClassName $ (toKebabCase $ reflectSymbol (Proxy :: Proxy name)) <> "-" <> (show a) <> "-" <> (show b)

genericClassName :: forall a rep. Generic a rep => GenericAsClassName rep => a -> ClassName
genericClassName = asClassName' <<< from

data Display = Inline | Block | Hidden | Flex | InlineFlex

derive instance Generic Display _
instance AsClassName Display where
  asClassName = genericClassName

data Overflow = OverflowAuto | OverflowHidden | OverflowScroll

derive instance Generic Overflow _
instance AsClassName Overflow where
  asClassName = genericClassName

data Position = Static | Fixed | Relative | Absolute | Sticky

derive instance Generic Position _
instance AsClassName Position where
  asClassName = genericClassName

data FlexDirection = FlexRow | FlexColumn

derive instance Generic FlexDirection _
instance AsClassName FlexDirection where
  asClassName = genericClassName

data FlexStretch = FlexAuto | FlexInitial | Flex1 | FlexNone

derive instance Generic FlexStretch _
instance AsClassName FlexStretch where
  asClassName = genericClassName

data Gap = Gap Int | RowGap Int | ColumnGap Int

derive instance Generic Gap _
instance AsClassName Gap where
  asClassName = genericClassName

data Z = Z Int

derive instance Generic Z _
instance AsClassName Z where
  asClassName = genericClassName

data Elevation = Shadow Int

derive instance Generic Elevation _
instance AsClassName Elevation where
  asClassName = genericClassName

data Opacity = Opacity0 | Opacity10 | Opacity40 | Opacity70 | Opacity100

derive instance Generic Opacity _
instance AsClassName Opacity where
  asClassName = genericClassName

data Content = ContentStart | ContentEnd | ContentCenter | ContentBetween | ContentAround | ContentEvenly

derive instance Generic Content _
instance Show Content where
  show = unwrap <<< genericClassName

data Align = Align Content

derive instance Generic Align _
instance AsClassName Align where
  asClassName = genericClassName

data Justify = Justify Content

derive instance Generic Justify _
instance AsClassName Justify where
  asClassName = genericClassName

data Responsive a = Small a | Medium a | Large a | ExtraLarge a

instance AsClassName a => AsClassName (Responsive a) where
  asClassName (Small a) = wrap $ "sm:" <> (unwrap $ asClassName a)
  asClassName (Medium a) = wrap $ "md:" <> (unwrap $ asClassName a)
  asClassName (Large a) = wrap $ "lg:" <> (unwrap $ asClassName a)
  asClassName (ExtraLarge a) = wrap $ "xl:" <> (unwrap $ asClassName a)

data AlignItems = AlignItemsStretch | AlignItemsStart | AlignItemsEnd | AlignItemsCenter

derive instance Generic AlignItems _
instance AsClassName AlignItems where
  asClassName = genericClassName

data AlignSelf = AlignSelfStretch | AlignSelfStart | AlignSelfEnd | AlignSelfCenter

derive instance Generic AlignSelf _
instance AsClassName AlignSelf where
  asClassName = genericClassName

data PlacementPortion = PlaceAuto | PlaceZero | PlaceHalf | PlaceFull

derive instance Generic PlacementPortion _
instance Show PlacementPortion where
  show = unwrap <<< genericClassName

data Anchor = Top | Bottom | Left | Right

derive instance Generic Anchor _
instance Show Anchor where
  show = unwrap <<< genericClassName

data Placement = Placement PlacementPortion Anchor

derive instance Generic Placement _
instance AsClassName Placement where
  asClassName = genericClassName

data Field = Field

derive instance Generic Field _
instance AsClassName Field where
  asClassName = genericClassName

data Formgrid = Formgrid

derive instance Generic Formgrid _
instance AsClassName Formgrid where
  asClassName = genericClassName

data Grid = Grid

derive instance Generic Grid _
instance AsClassName Grid where
  asClassName = genericClassName

data Col = Col | ColN Int | ColFixed

instance AsClassName Col where
  asClassName Col = wrap "col"
  asClassName (ColN n) = wrap $ "col-" <> (show n)
  asClassName ColFixed = wrap $ "col-fixed"

data TextSize = TextXs | TextSm | TextBase | TextLg | TextXl | Text2xl | Text3xl

derive instance Generic TextSize _
instance AsClassName TextSize where
  asClassName = genericClassName

data TextWeight = FontLight | FontNormal | FontMedium | FontSemibold | FontBold

derive instance Generic TextWeight _
instance AsClassName TextWeight where
  asClassName = genericClassName

data TextAlign = TextCenter | TextJustify | TextLeft | TextRight

derive instance Generic TextAlign _
instance AsClassName TextAlign where
  asClassName = genericClassName

data TextDecoration = Underline | LineThrough | NoUnderline

derive instance Generic TextDecoration _
instance AsClassName TextDecoration where
  asClassName = genericClassName

data TextOverflow = TextOverflowEllipsis

derive instance Generic TextOverflow _
instance AsClassName TextOverflow where
  asClassName = genericClassName

data ListType = ListNone | ListDisc | ListDecimal

derive instance Generic ListType _
instance AsClassName ListType where
  asClassName = genericClassName

data TextVerticalAlign = VerticalAlignTop | VerticalAlignMiddle | VerticalAlignBottom | VerticalAlignSub | VerticalAlignSuper

derive instance Generic TextVerticalAlign _
instance AsClassName TextVerticalAlign where
  asClassName = genericClassName

data UserSelect = SelectAll | SelectNone

derive instance Generic UserSelect _
instance AsClassName UserSelect where
  asClassName = genericClassName

data Maxed = WFull | WScreen | HFull | HScreen

derive instance Generic Maxed _
instance AsClassName Maxed where
  asClassName = genericClassName

data Margins = MxAuto | M Int | Mt Int | Mb Int | Ml Int | Mr Int | Mx Int | My Int

derive instance Generic Margins _
instance AsClassName Margins where
  asClassName = genericClassName

data Paddings = P Int | Pt Int | Pb Int | Pl Int | Pr Int | Px Int | Py Int

derive instance Generic Paddings _
instance AsClassName Paddings where
  asClassName = genericClassName

data Width = WRem Int

instance AsClassName Width where
  asClassName (WRem i) = ClassName $ "w-" <> (show i) <> "rem"

toProps :: forall a. ClassName -> Array (ReactProps a)
toProps a = [ className $ unwrap $ a ]
