#!/bin/sh
#
# Meteor settings
#
echo "-----> Adding profile script to set METEOR_SETTING"

# wget https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 -O jq
curl -o "$APP_CHECKOUT_DIR"/jq https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64
chmod +x "$APP_CHECKOUT_DIR"/jq
JQ="$APP_CHECKOUT_DIR/jq"

if [ -z "PRODUCTION" ] ; then
    echo "FATAL: PRODUCTION is not defined, it should be 'true' or 'false'"
    exit 1
else
    PROD=$PRODUCTION
fi

if $PROD ; then
    # Build the production settings
    echo "Production deploy"

    SETTINGS=`$JQ -s '.[0] * .[1]' $APP_CHECKOUT_DIR/server/settings/common.json $APP_CHECKOUT_DIR/server/settings/production.json`
else
    # Build the staging settings
    echo "Staging deploy"

    # For staging we pre-pend "10" to the version number to make it obvious if a device is 
    # connecting to Staging or Production. 
    echo "creating staging versions"
    STAGING_VERSION=10$($JQ '.public.version' $APP_CHECKOUT_DIR/server/settings/common.json | tr -d '"')
    echo $STAGING_VERSION
    echo `$JQ --version`
    echo "combining settings"
    # Merge the common and staging specific settings, and include the staging version no.
    # CONFIG="$APP_CHECKOUT_DIR/server/settings/config.json"
    SETTINGS=`$JQ --arg VERSION "$STAGING_VERSION" -s '.[0] * .[1] | .public.version |= $VERSION' $APP_CHECKOUT_DIR/server/settings/common.json $APP_CHECKOUT_DIR/server/settings/staging.json`
fi

echo $SETTINGS

cat > "$APP_CHECKOUT_DIR"/.profile.d/meteor.sh <<EOF
  #!/bin/bash
    export METEOR_SETTINGS=$SETTINGS
EOF
