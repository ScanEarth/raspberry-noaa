#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import os
import sys
import tweepy

CONSUMER_KEY = os.environ['CONSUMER_KEY']
CONSUMER_SECRET = os.environ['CONSUMER_SECRET']
ACCESS_TOKEN_KEY = os.environ['ACCESS_TOKEN_KEY']
ACCESS_TOKEN_SECRET = os.environ['ACCESS_TOKEN_SECRET']

auth = tweepy.OAuthHandler(CONSUMER_KEY, CONSUMER_SECRET)
auth.set_access_token(ACCESS_TOKEN_KEY, ACCESS_TOKEN_SECRET)
api = tweepy.API(auth)
swedenFlag = u'\U0001F1F8' + u'\U0001F1EA'

filenames = []
for element in sys.argv[3:]:
  filenames.append(element)

media_ids = []
for filename in filenames:
  res = api.media_upload(filename)
  media_ids.append(res.media_id)

api.update_status(status=swedenFlag + ' Satellitbilder: ' + sys.argv[1] + '. Max elevering: ' + sys.argv[2] + ' grader. #NOAA #weather #noaasatellite #wxtoimg #raspberrypi #sverige #satellitbilder', media_ids=media_ids)
