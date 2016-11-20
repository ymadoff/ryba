
# `hue_adduser(options, callback)`

Create a Hue user.

Options include:

*   `url`
*   `username`   
*   `password`   
*   `groups`   
*   `first_name`   
*   `last_name`   
*   `email`   
*   `is_superuser`   
*   `admin.username`   
*   `admin.password`   

## Source Code

    module.exports = (options) ->

      params = options.config
      throw Error "Required option 'url'" unless params.url
      throw Error "Required option 'username'" unless params.username
      throw Error "Required option 'password'" unless params.password1
      throw Error "Required option 'groups'" unless params.groups
      throw Error "Required option 'admin'" unless params.admin

      COOKIES = "cookies.txt"


      admin = params.admin
      groups = params.groups
      hue_url = params.url
      delete params.admin
      delete params.groups
      delete params.url

      url_params = ''
      for prop,value of params
        url_params += "&#{prop}=#{value}"

      url_params += "&password2=#{params.password1}&is_active=true"
      url_params += "&groups=#{groups.join("&groups=")}"

      @execute
        cmd: """
        URL="#{hue_url}"
        LOGIN_URL=$URL/accounts/login/?next=/
        POST_URL=$URL/useradmin/users/new

        YOUR_USER='#{admin.username}'
        YOUR_PASS='#{admin.password}'

        CURL_BIN="curl -s -k -c #{COOKIES} -b #{COOKIES} -e $LOGIN_URL"

        echo  "AUTH: GET CSRF_TOKEN ..."
        $CURL_BIN $LOGIN_URL > /dev/null
        CSRF_TOKEN="$(grep csrftoken #{COOKIES} | sed 's/^.*csrftoken\s*//' | tr -d ' ' | tr -d '\t')"
        echo $CSRF_TOKEN
        echo " PERFORM LOGIN ..."
        echo "$CURL_BIN -d csrfmiddlewaretoken=$CSRF_TOKEN&username=$YOUR_USER&password=$YOUR_PASS -X POST $LOGIN_URL"

        $CURL_BIN -d "csrfmiddlewaretoken=$CSRF_TOKEN&username=$YOUR_USER&password=$YOUR_PASS" -X POST $LOGIN_URL

        CSRF_TOKEN="$(grep csrftoken #{COOKIES} | sed 's/^.*csrftoken\s*//' | tr -d ' ' | tr -d '\t')"
        echo $CSRF_TOKEN

        echo  " CREATING USER ..."
        echo "$CURL_BIN --header X-CSRFToken:$CSRF_TOKEN -d csrfmiddlewaretoken=$CSRF_TOKEN#{url_params} -X POST $POST_URL"

        RESPONSE=$($CURL_BIN --header "X-CSRFToken:$CSRF_TOKEN" -d "csrfmiddlewaretoken=$CSRF_TOKEN#{url_params}" -X POST $POST_URL)

        if echo $RESPONSE | grep -q "CSRF token missing or incorrect\|403 Forbidden\|CSRF Error";then echo "SOMETHING WRONG WITH CSRF TOKEN" && exit 2;fi
        if echo $RESPONSE | grep -q "html";then echo "SOMETHING WRONG WITH THE PARAMATERS" && exit 2;else echo "USER #{params.username} CREATED";fi
        echo " LOGOUT"

        """
        trap: true
      @remove
        source: COOKIES

    module.exports.register = ->
      @registry.register 'hue_adduser', module.exports unless @registry.registered 'hue_adduser'

