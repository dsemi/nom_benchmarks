{-# LANGUAGE OverloadedStrings #-}

import           Control.Applicative              ((<$>), (<*>))
import           Criterion.Main                   (bench, bgroup, defaultMain,
                                                   env, nfIO, whnf, whnfIO)
import qualified Data.Attoparsec.Binary           as Bin
import qualified Data.Attoparsec.ByteString.Char8 as C
import qualified Data.ByteString                  as B
import qualified Data.ByteString.Char8            as C8
import           Data.Word

data LV = LV Int BOX deriving Show
data BOX = FTYP B.ByteString Word32 [B.ByteString] | FREE | MOOV | SKIP | MDAT deriving Show

ftypBox :: C.Parser BOX
ftypBox = do
  C.string "ftyp"
  major_brand         <- C.take 4
  major_brand_version <- Bin.anyWord32be
  compatible_brands   <- C.many' (C.take 4)
  return $ FTYP major_brand major_brand_version compatible_brands

freeBox = do
  C.string "free"
  return  FREE
mdat = do
  C.string "mdat"
  return  MDAT
moov = do
  C.string "moov"
  return  MOOV
skip = do
  C.string "skip"
  return SKIP
mdra = C.string "mdra"
dref = C.string "dref"
cmov = C.string "cmov"
rmra = C.string "rmra"


mp4Box :: C.Parser LV
mp4Box = do
  length <- fromIntegral <$> Bin.anyWord32be
  Right value  <- C.parseOnly anyBox <$> C.take (length - 4)
  return $ LV length value

anyBox = C.choice [ftypBox, freeBox, moov, skip, mdat]

mp4Parser = C.many1 mp4Box

smallFile :: FilePath
smallFile = "../small.mp4"
bunnyFile :: FilePath
bunnyFile = "../bigbuckbunny.mp4"

setupEnv = do
  small <- B.readFile smallFile
  bunny <- B.readFile bunnyFile
  return (small, bunny)

criterion :: IO ()
criterion = defaultMain
    [
      env setupEnv $ \ ~(small,bunny) ->
      bgroup "IO"
        [
          bench "small"          $ whnf (C.parseOnly mp4Parser) small
        , bench "big buck bunny" $ whnf (C.parseOnly mp4Parser) bunny
        ]
    ]

main :: IO ()
main = criterion
--main = B.readFile smallFile >>= print . C.parseOnly mp4Parser
