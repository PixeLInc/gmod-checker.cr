doctype html
html
  head
    title GMOD | PixeLInc
    link href="https://fonts.googleapis.com/css?family=Lato" rel="stylesheet"
    script src="https://code.jquery.com/jquery-2.1.1.min.js"
    script src="settings.js"

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
  body
    div.maincontent
      div.card
        h1 Garry's Mod
        p A simplistic Garry's Mod tool to check the sharing status and weekly hours of multiple Steam IDs
        p Just paste in a list of Steam IDs, or type them in however you want.
        p Please note - The request may take some time depending on how many steam ids you put. In the future I will be doing a more live implementation (which ive started already) but for now its just one big bulk request!
        div.error
        br
        textarea id="steam_ids" placeholder="STEAM_0:X:XXXX, STEAM_0:XXXX\nSTEAM_0:X:XXXX STEAM_0:X:XXXX"
        br
        span
          input type="radio" value="Shared" id="shared" name="check" checked="checked"
          label Shared
          input type="radio" value="Weekly" name="check"
          label Weekly
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
      div.card
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

      window.onload = function(event) {
        if (currentMode == 'websocket') {
          connect();
          registerCallback(ws_callback);
        }
      }

      function createCard(title, desc, sobj, suser) {
        $('.results').append(`
          <div class='card'>
            <h1 style='color: ${sobj.sharing ? 'darkred' : 'green'}'> ${title} </h1>
            <p> ${desc} </p>
            <span class='cardlinks'> <a href='http://steamcommunity.com/profiles/${suser.steamid}> Profile of user </a> </span>
          </div>
        `);
      }

      function createCards(json) {
        var results = json.results[0];
        console.log(results);

        var keys = Object.keys(results);
        var dCard = $('.card')[1];
        if(keys.length > 0)
          dCard.remove();
        else {
          var children = dCard.children;
          children[0].innerHTML = 'No results!';
          children[1].innerHTML = 'Nothing was found for the specified ids!';
        }

        Object.keys(results).forEach(function(key) {
          var sObj = results[key];
          var steam_user = sObj.steam_user;

          createCard(`${steam_user.personaname} (${steam_user.id})`, sObj.sharing ? `is family sharing with ${sObj.lender}` : 'is not family sharing.', sObj, steam_user);
        });
      }

      function ws_callback(data) {
        if (data.type == 'result') {
          console.log('creating a card!');
          createCard(data.title, data.desc, false);
        }
      }

      checkBtn.onclick = function(event) {
        var text = $('#steam_ids').val().trim();
        var matched = text.match(/STEAM_[0-5]:[01]:\\d+/g);
        var shared = document.getElementById('shared').checked ? true : false;

        if (matched == undefined || matched == null) {
          $('.error').hide().html('<p> No valid IDs passed </p>').fadeIn();
        }

        if (matched.length > 0) {
          console.log('Sending the data over to the server!');
          var toSend = matched.join(', ');
          console.log(toSend);

          if(currentMode == 'websocket')
            send_ws(toSend);
          else {
            $.ajax({
              url: 'check',
              data: `steamids=${toSend}&type=${shared ? 'shared' : 'recent'}`,
              success:function(data) {
                console.log(`Got ${JSON.stringify(data)}`);
                $('.error').hide();

                if(!data['results'][0].hasOwnProperty('error'))
                  createCards(data);
                else
                  $('.error').hide().html(`<p> ${data['results'][0].error} </p>`).fadeIn();
              },
              error:function(j, t, e) {
                $('.error').hide().html('<p> An error occurred! (Server may be down)</p>').fadeIn();
              }
            });
          }
        } else {
          $('.error').hide().html('<p> No valid IDs passed </p>').fadeIn();
        }
      }



