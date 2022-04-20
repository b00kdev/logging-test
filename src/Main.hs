{-# language DataKinds             #-}
{-# language FlexibleContexts      #-}
{-# language PartialTypeSignatures #-}
{-# language OverloadedLabels      #-}
{-# language OverloadedStrings     #-}
{-# language TypeApplications      #-}
{-# OPTIONS_GHC -fno-warn-partial-type-signatures #-}

module Main where

import Colog
import Control.Monad.IO.Class (liftIO)

import Mu.GRpc.Server
import Mu.Server

import Schema

main :: IO ()
main = runGRpcAppTrans msgProtoBuf 8080 logger server
  where logger = usingLoggerT (LogAction $ liftIO . putStrLn)

server :: (MonadServer m, WithLog env Colog.Message m) => SingleServerT i Service m _
server = singleService (method @"SayHello" sayHello)

sayHello :: (MonadServer m, WithLog env Colog.Message m) => HelloRequestMessage -> m HelloReplyMessage
sayHello (HelloRequestMessage nm) = do
  logInfo "running hi"
  pure $ HelloReplyMessage ("hi, " <> nm)