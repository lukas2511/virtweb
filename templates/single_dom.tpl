{% extends "base.tpl" %}
{% block head %}

<script type="text/javascript">

var tid = setInterval(refresh, 250);

function refresh() {
    $.getJSON('/dom/{{ domain.uuid }}.json', function ( domain ) {
        if(domdiv = document.getElementById("dom-" + domain.uuid)) {
            $("#dom-" + domain.uuid + " img").attr('src', 'data:' + domain.screenshot.mime + ';base64,' + domain.screenshot.data);
            if(domain.status == 'running'){
                if($("#dom-" + domain.uuid + " button.power").text()!="OFF"){
                    $("#dom-" + domain.uuid + " button.power").attr('name', 'off')
                    $("#dom-" + domain.uuid + " button.power").text('OFF')
                }
            }else{
                if($("#dom-" + domain.uuid + " button.power").text()!="ON"){
                    $("#dom-" + domain.uuid + " button.power").attr('name', 'on')
                    $("#dom-" + domain.uuid + " button.power").text('ON')
                }
            }
            $("#dom-" + domain.uuid + " h1").html(domain.name + " (" + domain.uuid + ")");
        }
    });
}

var keyqueue = []
var keys = []
var directinput = false;

function change_cdrom(form) {
    iso = encode64(form.iso.value);
    $.get('/dom/{{ domain.uuid }}/mount/' + iso, function(data){
        self.location.href = '/dom/{{ domain.uuid }}';
    });
}

function redefine_dom(form) {
    name = form.name.value;
    memory = form.memory.value
    vcpu = form.vcpu.value
    $.get('/dom/{{ domain.uuid }}/edit/' + name + '/' + vcpu + '/' + memory, function(data){
        self.location.href = '/dom/{{ domain.uuid }}';
    });
}

function toggle_directinput() {
    current = $("#dom-{{ domain.uuid }} button.directinput").text();
    if($("#dom-{{ domain.uuid }} button.directinput").text()=="DIRECT CONTROL"){
        $("#dom-{{ domain.uuid }} button.directinput").text('TEXTBOX');
        $("#dom-{{ domain.uuid }} .sendtext").css('display', 'inline');
        directinput = false;
    }else{
        $("#dom-{{ domain.uuid }} button.directinput").text('DIRECT CONTROL');
        $("#dom-{{ domain.uuid }} .sendtext").css('display', 'none');
        directinput = true;
    }
}

function sendtext() {
    text = document.getElementById('sendtext_text').value;
    for (var i = 0, len = text.length; i < len; i++){
        if(typeof KEYCODES[text[i]] != 'number' && typeof KEYCODES[text[i]] != 'object') {
            alert("Unknown character '" + text[i] + "' at position " + i);
            return;
        }
    }
    for (var i = 0, len = text.length; i < len; i++){
        if(typeof KEYCODES[text[i]] == 'object') {
            keyqueue.push(KEYCODES[text[i]].join(','));
        }else{
            keyqueue.push(KEYCODES[text[i]]);
        }
    }
    while(keyqueue.length>0){
        key = keyqueue.shift();
        console.log(key);
        $.ajax({'url': "/sendkeys/{{ domain.uuid }}/0/" + key, async: false});
    }
    document.getElementById('sendtext_text').value='';
}

$(window).load(function() {
    $('#myTab a').click(function (e) {
        e.preventDefault();
        $(this).tab('show');
    })
});

$(document).keyup(function(e) {
    if(directinput){
        keys.splice(keys.indexOf(e.keyCode));
    }
});

$(document).keydown(function(e) {
    if(directinput){
        e.preventDefault();
        if(keys.indexOf(e.keyCode)==-1) { keys.push(e.keyCode); }
        console.log(keys.join(','));
        $.ajax({'url': "/sendkeys/{{ domain.uuid }}/0/" + keys.join(','), async: false});
    }
});

</script>

{% endblock %}
{% block content %}
<ul class="nav nav-tabs" id="myTab">
  <li class="active"><a href="#control">Control</a></li>
  <li><a href="#stats" onclick="if(directinput) toggle_directinput();">Stats</a></li>
  <li><a href="#edit" onclick="if(directinput) toggle_directinput();">Edit</a></li>
</ul>
<div id='content' class="tab-content">
  <div class="tab-pane active" id="control">
    <div id="dom-{{ domain.uuid }}" class="domain">
      <h1>{{ domain.name }} ({{ domain.uuid }})</h1>
      <button class="power btn btn-sm btn-default" name="on" onclick="$.get('/power/{{ domain.uuid }}/' + this.name);">ON</button>
      <button class="directinput btn btn-sm btn-default" onclick="toggle_directinput();">TEXTBOX</button>
      <input style="display:inline;width:500px;" class="sendtext form-control" type="text" id="sendtext_text" value="test-text" />
      <button style="display:inline;" class="sendtext btn btn-sm btn-default" id="sendtext_button" onclick="sendtext();">SEND</button>
      <br /><br />
      <img style="max-width:100%;max-height:100%;" src="data:{{ domain.screenshot.mime }};base64,{{ domain.screenshot.data }}" />
    </div>
  </div>
  <div class="tab-pane" id="stats">
    todo
  </div>
  <div class="tab-pane" id="edit">
    <h3>Storage</h3>
    <form class="form-horizontal" role="form" onsubmit="change_cdrom(this); return false;">
      <div class="form-group">
        <label for="iso" class="col-sm-2 control-label">ISO</label>
        <div class="col-sm-10">
          <select name="iso" class="form-control">
          <option>---</option>
          {% for iso in isos %}
            <option{% if iso == domain.cdroms[0].file %} selected="selected"{% endif %}>{{ iso }}</option>
          {% endfor %}
          </select>
        </div>
      </div>
      <div class="form-group">
        <div class="col-sm-offset-2 col-sm-10">
          <button type="submit" class="btn btn-default">Mount</button>
        </div>
      </div>
    </form>

    <h3>VM Settings</h3>
    <br />
    <form class="form-horizontal" role="form" onsubmit="redefine_dom(this); return false;">
      <div class="form-group">
        <label for="name" class="col-sm-2 control-label">Name</label>
        <div class="col-sm-10">
          <input type="text" name="name" value="{{ domain.name }}" class="form-control" />
        </div>
      </div>
      <div class="form-group">
        <label for="memory" class="col-sm-2 control-label">Max. Memory</label>
        <div class="col-sm-10">
          <input type="text" name="memory" value="{{ domain.memory }}" class="form-control" />
        </div>
      </div>
      <div class="form-group">
        <label for="vcpu" class="col-sm-2 control-label">Num. VCPUs</label>
        <div class="col-sm-10">
          <input type="text" name="vcpu" value="{{ domain.vcpu }}" class="form-control" />
        </div>
      </div>
      <div class="form-group">
        <div class="col-sm-offset-2 col-sm-10">
          <button type="submit" class="btn btn-default">Redefine<span style="color:red;">*</span></button><br />
          <span style="color:red;">* This will stop the machine and cancel all background jobs!<br />(Also there are no sanity checks. And your VM will get deleted if you do something wrong...)</span>
        </div>
      </div>
    </form>
  </div>
</div>

{% endblock %}
