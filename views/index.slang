doctype html
html
  head
    title GMOD | PixeLInc
    link href="https://fonts.googleapis.com/css?family=Lato" rel="stylesheet"
    script src="https://code.jquery.com/jquery-2.1.1.min.js"
    script src="settings.js"
    script src="websocket.js"

    css:
      body {
        background-color: #202020;
        color: white;
        margin: 0 auto;
        font-family: 'Lato', sans-serif;

        padding: 2em;
      }

      input {
        margin-bottom: 15px;
      }
      input[type="radio"] {
        vertical-align: top;
      }
      label {
        vertical-align: top;
      }

      textarea {
        margin-bottom: 15px;

        background: #101010;
        border: 0;
        color: white;

        height: 208px;
        width: 591px;
       }

      .maincontent {
        width: 100%;
      }

      .results {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(30%, 1fr));
      }

      .card > h1 {
        margin-bottom: -10px;
      }

      .card > h1 > a {
        text-decoration: none;
        color: white;
        cursor: pointer;
      }

      .card > h1 > a > img {
        width: 16px;
        height: 16px;
        position: absolute;
        margin-top: 12px;
      }

      .card {
        box-shadow: 0 4px 8px 0 rgba(0,0,0,0.2);
        transition: 0.3s;

        padding: 2px 16px;
        border-radius: 5px;

        margin: 10px;
      }

      .card:hover {
        box-shadow: 0 8px 16px 0 rgba(155,155,155,0.2);
      }

      .modal {
        display: none;
        position: fixed;
        z-index: 1;
        left: 0;
        top: 0;
        width: 100%;
        height: 100%;
        overflow: auto;

        background: rgba(0, 0, 0, .4);
      }

      .modalcontent {
        color: white;
        border: 2px solid #606060;
        background-color: #404040;
        margin: 15% auto;
        padding: 20px;
        width: 50%;

        text-align: center;
      }

      .error {
        display: none;
        color: red;
        font-size: 24px;

        border: 1px solid red;
        padding: 2px 10px;
      }

      .card img {
        width: 4em;
        float: right;

        padding: 5px;
      }
  body
    div.maincontent
      div.card
        h1 Garry's Mod
        p A simplistic Garry's Mod tool to check the sharing status of multiple Steam IDs
        p Just paste in a list of Steam IDs, or type them in however you want.
        div.error
        br
        textarea id="steam_ids" placeholder="STEAM_0:X:XXXX, STEAM_0:XXXX\nSTEAM_0:X:XXXX STEAM_0:X:XXXX"
        br
        span
          input type="radio" value="Shared" id="shared" name="check" checked="checked"
          label Shared
          input type="radio" value="Weekly" name="check" disabled=true
          label style="color: gray" Weekly
        br
        input type="button" value="Check" id="check-btn"

    div#modal.modal
      div.modalcontent
        h1 Page Settings
        p In here you can customize the color of the page, including the shadow, background, and text color!

        h4 Themes
        p (todo: light/dark/custom)

        h4 If custom, go down here:
        p This is some text, wow!

    div.results
      div.card#placeholder
        h1 Your results
        p will display here!

    javascript:
      var modal = document.getElementById('modal')
      var checkBtn = document.getElementById('check-btn');

      window.onclick = function(event) {
        if (event.target == modal) {
          modal.style.display = "none"
        }
      }

      // {"nonce": "123", "type": "batch_players", "data": { "players": [{}, {}] }}
      function updateCard(data) {
        data = data.data;
        var players = data.players;

        if (players.length == 0) return;
        console.log('[DEBUG] Got lending players: ' + players);

        for(i = 0; i < players.length; i++) {
          var player = players[i];

          $('#' + player.steamid).append(`
            <img src='${player.avatarfull}'/>
            <h1> <a href='${player.profileurl}'> ${player.personaname} <img src='steam_logo.svg'/> </a> </h1>
            <br>
            <span class='links'> <a href='https://seriousgmod.com/adminstats.php?sid=${player.id_32}'> AdminStats </a> </span>
          `);
        }

      }

      // example payload(s)
      // {"nonce": "123", "type": "player_result"/"batch_players"/"error", "data": { "player": {...}, "lender_id": "123"/null }
      function createCard(data) {
        // by now, type should've been validated to be 'result', so let's grab the data.
        // and also going to assume that all the data is in fact present and nothing is missing.
        data = data.data;
        var player = data.player;
        var lenderId = data.lender_id;
        // oof.
        var lenderMessage = "<font color='red'> is currently sharing with </font>";
        if (!lenderId)
          lenderMessage = "<font color='green'> is currently not sharing </font>";

        // remove the placeholder card if it exists.
        $('#placeholder').remove();

        if (lenderId && $('#' + lenderId).length != 0) {
          console.log('Card with ' + player.personaname + ' already exists!');
          return;
        }

        console.log('Creating card with ' + player.personaname);

        $('.results').append(`
          <div class='card' id='${lenderId}'>
            <img src='${player.avatarfull}'/>

            <h1> <a href='${player.profileurl}'> ${player.personaname} <img src='steam_logo.svg'/> </a> </h1>
            <h2> ${lenderMessage} ${lenderId} </h2>
            <span class='links'> <a href='https://seriousgmod.com/adminstats.php?sid=${player.id_32}'> AdminStats </a> </span>
            <hr/>
          </div>
        `);
      }

      function ws_callback(data) {
        if (data.type == 'player_result')
          createCard(data);
        else if (data.type == 'batch_players')
          updateCard(data);
        else
          console.log('Something went horribly wrong...');
      }

      checkBtn.onclick = function(event) {
        var text = $('#steam_ids').val().trim();
        var matched = text.match(/STEAM_[0-5]:[01]:\\d+/g);
        var shared = document.getElementById('shared').checked ? true : false;

        if (matched == undefined || matched == null) {
          $('.error').hide().html('<p> No valid IDs passed </p>').fadeIn();
        }

        if (matched.length > 0) {
          // Get a nonce from the server
          var rawIds = matched.join(',');
          var nonce = undefined;

          $.ajax({
            type: 'POST',
            url: '/api/check?steamids=' + rawIds,
            success:function(d) {
              console.log(d);

              json = $.parseJSON(d);
              nonce = json.nonce;

              // return error or something?
              if (nonce === undefined) return;

              // try and connect to WS and register
              console.log('[DEBUG] Attempting to send nonce to the server....');
              ws_connect();
              ws_registerCallback(ws_callback);

              // send that nonce
              ws_send(JSON.stringify({nonce: nonce}));
            }
          });
        } else {
          $('.error').hide().html('<p> No valid IDs passed </p>').fadeIn();
        }
      }
