<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <link rel="shortcut icon" href="/favicon.ico">
    <title>Bootstrap PHP Hello World</title>

    <!-- Bootstrap -->
    <!-- Latest compiled and minified CSS -->
    <link rel="stylesheet" href="//maxcdn.bootstrapcdn.com/bootstrap/3.3.6/css/bootstrap.min.css" integrity="sha384-1q8mTJOASx8j1Au+a5WDVnPi2lkFfwwEAa8hDDdjZlpLegxhjVME1fgjWPGmkzs7" crossorigin="anonymous">

    <!-- Optional theme -->
    <!-- <link rel="stylesheet" href="//maxcdn.bootstrapcdn.com/bootstrap/3.3.6/css/bootstrap-theme.min.css" integrity="sha384-fLW2N01lMqjakBkx3l/M9EahuwpSfeNvV63J5ezn3uZzapT0u7EYsXMjQV+0En5r" crossorigin="anonymous"> -->

    <!-- HTML5 Shim and Respond.js IE8 support of HTML5 elements and media queries -->
    <!-- WARNING: Respond.js doesn't work if you view the page via file:// -->
    <!--[if lt IE 9]>
      <script src="//oss.maxcdn.com/html5shiv/3.7.2/html5shiv.min.js"></script>
      <script src="//oss.maxcdn.com/respond/1.4.2/respond.min.js"></script>
    <![endif]-->

    <style type="text/css">
      html, body {background-color: #333; height: 100%; font-family: sans-serif;}
      body {margin: 0; padding-top: 50px; color: #fff; box-shadow: inset 0 0 100px rgba(0,0,0,.5);}
      .hello-banner {padding: 40px 15px; text-align: center; background-color: #222; border-radius: 6px;}
      .hello-banner h1 {font-size: 63px;}
      .hello-banner p {margin-bottom: 15px; font-size: 21px; font-weight: 200;}
    </style>
  </head>
  <body>
    <div class="container">
      <div class="hello-banner">
        <h1><?php print 'Hello, world!'; ?></h1>
        <p>This CentOS / Apache / PHP <?php print PHP_SAPI === 'cgi-fcgi' ? '(FastCGI)' : '(Standard)'; ?> service is running in a Docker container.</p>
<?php
  // Example method to detect SSL Offloaded requests
  if (array_key_exists('SERVER_PORT', $_SERVER) && $_SERVER['SERVER_PORT'] === '8443' && 
      array_key_exists('HTTP_X_FORWARDED_PROTO', $_SERVER) && $_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https') {
      $_SERVER['HTTPS'] = 'on';
?>
        <p>SSL Termination has been carried out on the load balancer. To detect HTTPS requestes use: <code>$_SERVER['PORT'] === '8443'</code> AND <code>$_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https'</code>.</p>
<?php
  }
?>
        <p class="lead">
<?php
  if (realpath(
      dirname(__FILE__) . "/_phpinfo.php"
  )) {
?>
          <a href="/_phpinfo.php" class="btn btn-lg btn-primary">PHP info</a>
<?php
  }
  if (extension_loaded('apc') &&
      realpath(
        dirname(__FILE__) . "/_apc.php"
      )
  ) {
?>
          <a href="/_apc.php" class="btn btn-lg btn-default">APC info</a>
<?php
  }
  if ($_SERVER['REMOTE_ADDR'] === '127.0.0.1') {
?>
          <a href="/server-status" class="btn btn-lg btn-default">Apache status</a>
<?php
  }
?>
        </p>
      </div>
    </div>

    <!-- jQuery (necessary for Bootstrap's JavaScript plugins) -->
    <script src="//ajax.googleapis.com/ajax/libs/jquery/1.11.3/jquery.min.js"></script>
    <!-- Latest compiled and minified JavaScript -->
    <script src="//maxcdn.bootstrapcdn.com/bootstrap/3.3.6/js/bootstrap.min.js" integrity="sha384-0mSbJDEHialfmuBBQP6A4Qrprq5OVfW37PRR3j5ELqxss1yVqOtnepnHVP9aJ7xS" crossorigin="anonymous"></script>
  </body>
</html>