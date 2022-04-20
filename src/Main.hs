{-# language DataKinds             #-}
{-# language FlexibleContexts      #-}
{-# language FlexibleInstances     #-}
{-# language MultiParamTypeClasses #-}
{-# language PartialTypeSignatures #-}
{-# language OverloadedStrings     #-}
{-# language TypeApplications      #-}
{-# OPTIONS_GHC -fno-warn-partial-type-signatures #-}

module Main where

import Colog
import Control.Monad.IO.Class (liftIO)
import Control.Monad.Reader (ReaderT, runReaderT)
import qualified Data.Text as T
import Mu.GRpc.Server
import Mu.Server
import Schema

data Env = Env
  { envServerPort :: !Int
  , envLogAction :: !(LogAction ServerErrorIO Message)
  }

instance HasLog Env Message (ReaderT Env ServerErrorIO) where
  getLogAction = liftLogAction . envLogAction
  setLogAction newLogAction env = env { envLogAction = hoistLogAction performLogsInReaderT newLogAction }
    where
      performLogsInReaderT :: ReaderT Env ServerErrorIO a -> ServerErrorIO a
      performLogsInReaderT action = runReaderT action env

main :: IO ()
main = usingLoggerT action $ do
  let env = Env 8080 (liftLogAction action)
  logInfo ("starting server on port " <> T.pack (show (envServerPort env)))
  liftIO $ runGRpcAppTrans msgProtoBuf (envServerPort env) (`runReaderT` env) server
  where
    action = cmap fmtMessage logTextStdout

server :: (MonadServer m, WithLog env Message m) => SingleServerT i Service m _
server = singleService (method @"SayHello" sayHello)

sayHello :: (MonadServer m, WithLog env Message m) => HelloRequestMessage -> m HelloReplyMessage
sayHello (HelloRequestMessage nm) = do
  logInfo "saying hello"
  pure $ HelloReplyMessage ("hi, " <> nm)