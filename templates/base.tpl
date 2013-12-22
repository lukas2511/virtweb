<!DOCTYPE html>
<html>
<head>
  <title>virtweb</title>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <script type="text/javascript" src="/static/js/jquery-1.9.1.js"></script>
  <script type="text/javascript" src="/static/js/keycodes.js"></script>
  <script type="text/javascript" src="/static/js/base64.js"></script>
  <link rel="stylesheet" href="/static/bootstrap/css/bootstrap.min.css">
  <link rel="stylesheet" href="/static/bootstrap/css/bootstrap-theme.min.css">
  {% block head %}{% endblock %}
</head>
<body>
<div class="container">
  <div class="navbar navbar-default" role="navigation">
    <div class="navbar-header">
      <button type="button" class="navbar-toggle" data-toggle="collapse" data-target=".navbar-collapse">
        <span class="sr-only">Toggle navigation</span>
        <span class="icon-bar"></span>
        <span class="icon-bar"></span>
        <span class="icon-bar"></span>
      </button>
      <a class="navbar-brand" href="/">virtweb</a>
    </div>
    <div class="navbar-collapse collapse">
      <ul class="nav navbar-nav">
        <li class="active"><a href="/">Machines</a></li>
        <li><a href="/storages/">Storages</a></li>
      </ul>
    </div>
<!--    <li><a href="#">Link</a></li>
            <li><a href="#">Link</a></li>
            <li class="dropdown">
              <a href="#" class="dropdown-toggle" data-toggle="dropdown">Dropdown <b class="caret"></b></a>
              <ul class="dropdown-menu">
                <li><a href="#">Action</a></li>
                <li><a href="#">Another action</a></li>
                <li><a href="#">Something else here</a></li>
                <li class="divider"></li>
                <li class="dropdown-header">Nav header</li>
                <li><a href="#">Separated link</a></li>
                <li><a href="#">One more separated link</a></li>
              </ul>
            </li>
          </ul>
          <ul class="nav navbar-nav navbar-right">
            <li class="active"><a href="./">Default</a></li>
            <li><a href="../navbar-static-top/">Static top</a></li>
            <li><a href="../navbar-fixed-top/">Fixed top</a></li>
          </ul>
        </div>-->



  </div>
  {% block content %}{% endblock %}
</div>
<script type="text/javascript" src="/static/bootstrap/js/bootstrap.min.js"></script>
</body>
</html>
