{% extends "base.tpl" %}
{% block head %}
<style type="text/css">
.domain {
    height:300px;
}
</style>

<script type="text/javascript">

var tid = setInterval(refresh, 100);

function refresh() {
    $.getJSON('/domains.json', function ( domains ) {
        $.each(domains, function(key, domain) {
            if(domdiv = document.getElementById(domain.uuid)) {
                $("#" + domain.uuid + " h3").html(domain.name);
                if(domain.status == "running" && !$("#" + domain.uuid + " .panel").hasClass('panel-success')){
                    $("#" + domain.uuid + " .panel").addClass('panel-success');
                    $("#" + domain.uuid + " .panel").removeClass('panel-danger');
                }
                if(domain.status == "stopped" && !$("#" + domain.uuid + " .panel").hasClass('panel-danger')){
                    $("#" + domain.uuid + " .panel").addClass('panel-danger');
                    $("#" + domain.uuid + " .panel").removeClass('panel-success');
                }
                $("#" + domain.uuid + " img").attr('src', 'data:' + domain.screenshot.mime + ';base64,' + domain.screenshot.data);
            }else{
                newdiv  = '<div id="' + domain.uuid +'" class="domain col-xs-6 col-sm-4" style="width:300px;">';
                newdiv += ' <a href="/dom/' + domain.uuid + '">';
                newdiv += '  <div class="panel panel-normal">';
                newdiv += '   <div class="panel-heading">';
                newdiv += '    <h3 class="panel-title">' + domain.name + '</h3>';
                newdiv += '   </div>';
                newdiv += '   <div class="panel-body">';
                newdiv += '    <img style="max-height:100%;max-width:100%;" src="data:' + domain.screenshot.mime + ';base64,' + domain.screenshot.data + '" />';
                newdiv += '   </div>';
                newdiv += '  </div>';
                newdiv += ' </a>';
                newdiv += '</div>';
                $("#domains").append(newdiv);
            }
        });
        $('.domain').each(function(i, obj) {
            stillexists=false;
            $.each(domains,function(key,domain){
                if(domain.uuid == obj.id) stillexists=true;
            });
            if(!stillexists) obj.remove();
        });
    });
}

</script>

{% endblock %}
{% block content %}
<div class="row" id="domains">
{% for domain in domains %}
  <div id="{{ domain.uuid }}" class="domain col-xs-6 col-sm-4" style="width:300px;">
    <a href="/dom/{{ domain.uuid }}">
      <div class="panel panel-{% if domain.status == "running" %}success{% else %}danger{% endif %}">
        <div class="panel-heading">
          <h3 class="panel-title">{{ domain.name }}</h3>
        </div>
        <div class="panel-body">
          <img style="max-height:100%;max-width:100%;" src="data:{{ domain.screenshot.mime }};base64,{{ domain.screenshot.data }}" />
        </div>
      </div>
    </a>
  </div>
{% endfor %}
</div>

<button onclick="self.location.href='/new/';" type="button" class="btn btn-lg btn-primary">+</button>

{% endblock %}
