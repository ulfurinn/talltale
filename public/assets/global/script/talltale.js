"use strict";

function encounter(id) {
    new Ajax.Request("/action", {
        method: "post",
        postBody: JSON.stringify({encounter: id}),
        onSuccess: function(response) {
            var resp = JSON.parse(response.responseText);
            console.log(resp);
            if(resp.error) {
                alert(resp.error);
            } else {
                window.location.reload();
            }
        }
    });
}

function choice(id) {
    new Ajax.Request("/action", {
        method: "post",
        postBody: JSON.stringify({choice: id}),
        onSuccess: function(response) {
            var resp = JSON.parse(response.responseText);
            console.log(resp);
            if(resp.error) {
                alert(resp.error);
            } else {
                window.location.reload();
            }
        }
    });
}
