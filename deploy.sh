#!/bin/bash
set -e

flutter build web
cp vercel.json build/web/

cd build/web
VERCEL_PROJECT_ID=prj_fUGGi7j8GNNdOzyPh7JLHk0heyil VERCEL_ORG_ID=team_qecEEyWGrh4yVPFCEhbws5zD vercel --prod --yes