<?php

//
// tailFile
//
// Monitor a file and print new data to the browser as it
// becomes available.
//

function tailFile($path)
{

  $tail = popen('tail -50f ' . escapeshellarg($path) . ' 2>&1', 'r');
  if (!$tail) {
    trigger_error('tail failed.', E_USER_ERROR);
  } elseif (stream_set_blocking($tail, 0) === false) {
    trigger_error('stream_set_blocking', E_USER_ERROR);
  } else {
    $buf = '';
    $bytes = 0;
    $updateTime = 0;

    for (;;) {
      if (stream_select($r = array($tail), $w = null, $x = null, 9, 0)
          === false) {
        trigger_error('stream_select', E_USER_ERROR);
        break;
      }

      $buf .= fread($tail, 8192);
      $len = strlen($buf);
      $part = false;

      if (($nl = strrpos($buf, "\n")) !== false) {
        $part = substr($buf, 0, $nl + 1);
        $buf = substr($buf, $nl + 1);
      } elseif ($len > 65536 || time() - $updateTime > 5) {
        $part = $buf;
        $buf = '';
      }

      if ($part !== false) {
        $updateTime = time();
        $part = htmlentities($part, ENT_QUOTES);
        $bytes += strlen($part);
        echo '';
        echo $part;
        echo '';
        if ($bytes > 262144) {
          echo '';
        }
        flush();
      }

      sleep(1);
    }

    pclose($tail) or trigger_error('pclose', E_USER_ERROR);
  }

  echo '
';
}

tailFile('/var/log/system.log');

?>