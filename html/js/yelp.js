
yelp_paint_zoom = function (zoom, zoomed) {
  var ctxt = zoom.children('canvas')[0].getContext('2d');
  ctxt.strokeStyle = ctxt.fillStyle = '#2e3436'
  ctxt.clearRect(0, 0, 10, 10);
  ctxt.strokeRect(0.5, 0.5, 9, 9);
  if (zoomed) {
    ctxt.fillRect(1, 1, 9, 4);
    ctxt.fillRect(5, 5, 4, 4);
    zoom.attr('title', zoom.attr('data-zoom-out-title'));
  }
  else {
    ctxt.fillRect(1, 5, 4, 4);
    zoom.attr('title', zoom.attr('data-zoom-in-title'));
  }
}
$.fn.yelp_auto_resize = function () {
  var fig = $(this);
  if (fig.is('img'))
    fig = fig.parents('div.figure').eq(0);
  if (fig.data('yelp-zoom-timeout') != undefined) {
    clearInterval(fig.data('yelp-zoom-timeout'));
    fig.removeData('yelp-zoom-timeout');
  }
  var imgs = fig.find('img');
  for (var i = 0; i < imgs.length; i++) {
    var img = $(imgs[i]);
    if (img.data('yelp-load-bound') == true)
      img.unbind('load', fig.yelp_auto_resize);
    if (!imgs[i].complete) {
      img.data('yelp-load-bound', true);
      img.bind('load', fig.yelp_auto_resize);
      return false;
    }
  }
  $(window).unbind('resize', yelp_resize_imgs);
  var zoom = fig.children('div.inner').children('a.zoom');
  for (var i = 0; i < imgs.length; i++) {
    var img = $(imgs[i]);
    if (img.data('yelp-original-width') == undefined) {
      img.data('yelp-original-width', img.width());
    }
    if (img.data('yelp-original-width') > img.parent().width()) {
      if (img.data('yelp-zoomed') != true) {
        img.width(img.parent().width());
      }
      zoom.show();
    }
    else {
      img.width(img.data('yelp-original-width'));
      zoom.hide();
    }
  }
  /* The image scaling above can cause the window to resize if it causes
   * scrollbars to disappear or reapper. Unbind the resize handler before
   * scaling the image. Don't rebind immediately, because we'll still get
   * that resize event in an idle. Rebind on the callback instead.
   */
  var reresize = function () {
    $(window).unbind('resize', reresize);
    $(window).bind('resize', yelp_resize_imgs);
  }
  $(window).bind('resize', reresize);
  return false;
};
yelp_resize_imgs = function () {
  $('div.figure img').parents('div.figure').each(function () {
    var div = $(this);
    if (div.data('yelp-zoom-timeout') == undefined)
      div.data('yelp-zoom-timeout', setTimeout(function () { div.yelp_auto_resize() }, 1));
  });
  return false;
};
$(document).ready(function () {
  $('div.figure img').parents('div.figure').each(function () {
    var fig = $(this);
    var zoom = fig.children('div.inner').children('a.zoom');
    zoom.append($('<canvas width="10" height="10"/>'));
    yelp_paint_zoom(zoom, false);
    zoom.data('yelp-zoomed', false);
    zoom.click(function () {
      var zoomed = !zoom.data('yelp-zoomed');
      zoom.data('yelp-zoomed', zoomed);
      zoom.parent().find('img').each(function () {
        var zimg = $(this);
        zimg.data('yelp-zoomed', zoomed);
        if (zoomed)
          zimg.width(zimg.data('yelp-original-width'));
        else
          zimg.width(zimg.parent().width());
        yelp_paint_zoom(zoom, zoomed);
      });
      return false;
    });
  });
  yelp_resize_imgs();
  $(window).bind('resize', yelp_resize_imgs);
});
Node.prototype.is_a = function (tag, cls) {
  if (this.nodeType == Node.ELEMENT_NODE) {
    if (tag == null || this.tagName.toLowerCase() == tag) {
      if (cls == null)
        return true;
      var clss = this.className.split(' ');
      for (var i = 0; i < clss.length; i++) {
        if (cls == clss[i])
          return true;
      }
    }
  }
  return false;
};
function yelp_init_media (media) {
  var control;
  var controlsDiv;
  var playControl;
  var rangeControl;
  var currentSpan;
  for (controlsDiv = media.nextSibling; controlsDiv; controlsDiv = controlsDiv.nextSibling)
{
    if (controlsDiv.is_a('div', 'media-controls'))
      break;
}
  if (!controlsDiv)
    return;
  for (control = controlsDiv.firstChild; control; control = control.nextSibling) {
    if (control.nodeType == Node.ELEMENT_NODE) {
      if (control.is_a('button', 'media-play'))
        playControl = control;
      else if (control.is_a('input', 'media-range'))
        rangeControl = control;
      else if (control.is_a('span', 'media-current'))
        currentSpan = control;
    }
  }

  var ttmlDiv;
  for (ttmlDiv = controlsDiv.nextSibling; ttmlDiv; ttmlDiv = ttmlDiv.nextSibling)
    if (ttmlDiv.is_a('div', 'media-ttml'))
      break;

  var playCanvas;
  for (playCanvas = playControl.firstChild; playCanvas; playCanvas = playCanvas.nextSibling)
    if (playCanvas.is_a('canvas', null))
      break;
  var playCanvasCtxt = playCanvas.getContext('2d');
  var paintPlayButton = function () {
    playCanvasCtxt.fillStyle = '#2e3436'
    playCanvasCtxt.clearRect(0, 0, 20, 20);
    playCanvasCtxt.beginPath();
    playCanvasCtxt.moveTo(5, 5);
    playCanvasCtxt.lineTo(5, 15);
    playCanvasCtxt.lineTo(15, 10);
    playCanvasCtxt.lineTo(5, 5);
    playCanvasCtxt.fill();
  }
  var paintPauseButton = function () {
    playCanvasCtxt.fillStyle = '#2e3436'
    playCanvasCtxt.clearRect(0, 0, 20, 20);
    playCanvasCtxt.beginPath();
    playCanvasCtxt.moveTo(5, 5);
    playCanvasCtxt.lineTo(9, 5);
    playCanvasCtxt.lineTo(9, 15);
    playCanvasCtxt.lineTo(5, 15);
    playCanvasCtxt.lineTo(5, 5);
    playCanvasCtxt.fill();
    playCanvasCtxt.beginPath();
    playCanvasCtxt.moveTo(11, 5);
    playCanvasCtxt.lineTo(15, 5);
    playCanvasCtxt.lineTo(15, 15);
    playCanvasCtxt.lineTo(11, 15);
    playCanvasCtxt.lineTo(11, 5);
    playCanvasCtxt.fill();
  }
  paintPlayButton();

  var mediaChange = function () {
    if (media.ended)
      media.pause()
    if (media.paused) {
      playControl.setAttribute('value', playControl.getAttribute('data-play-label'));
      paintPlayButton();
    }
    else {
      playControl.setAttribute('value', playControl.getAttribute('data-pause-label'));
      paintPauseButton();
    }
  }
  media.addEventListener('play', mediaChange, false);
  media.addEventListener('pause', mediaChange, false);
  media.addEventListener('ended', mediaChange, false);

  var playClick = function () {
    if (media.paused || media.ended)
      media.play();
    else
      media.pause();
  };
  playControl.addEventListener('click', playClick, false);

  var ttmlNodes = [];
  var ttmlNodesFill = function (node) {
    var child;
    if (node != null) {
      for (child = node.firstChild; child; child = child.nextSibling) {
        if (child.nodeType == Node.ELEMENT_NODE) {
          if (child.is_a(null, 'media-ttml-node'))
            ttmlNodes[ttmlNodes.length] = child;
          ttmlNodesFill(child);
        }
      }
    }
  }
  ttmlNodesFill(ttmlDiv);

  var timeUpdate = function () {
    rangeControl.value = parseInt((media.currentTime / media.duration) * 100);
    var mins = parseInt(media.currentTime / 60);
    var secs = parseInt(media.currentTime - (60 * mins))
    currentSpan.innerText = mins + (secs < 10 ? ':0' : ':') + secs;
    for (var i = 0; i < ttmlNodes.length; i++) {
      if (media.currentTime >= parseFloat(ttmlNodes[i].getAttribute('data-begin')) &&
          (!ttmlNodes[i].hasAttribute('data-end') ||
           media.currentTime < parseFloat(ttmlNodes[i].getAttribute('data-end')) )) {
        if (ttmlNodes[i].tagName == 'span')
          ttmlNodes[i].style.display = 'inline';
        else
          ttmlNodes[i].style.display = 'block';
      }
      else {
        ttmlNodes[i].style.display = 'none';
      }
    }
  };
  media.addEventListener('timeupdate', timeUpdate, false);

  var rangeChange = function () {
    media.currentTime = (parseInt(rangeControl.value) / 100.0)  * media.duration;
  };
  rangeControl.addEventListener('change', rangeChange, false);
};
document.addEventListener("DOMContentLoaded", function () {
  var vids = document.getElementsByTagName('video');
  for (var i = 0; i < vids.length; i++)
    yelp_init_media(vids[i]);
}, false);

$(document).ready( function () { jQuery.syntax({root: '', blockLayout: 'plain'},
function (options, html, container)
{ html.attr('class', container.attr('class')); return html; }); });

$(document).ready(function () {
  $('input.facet').change(function () {
    var control = $(this);
    var content = control.closest('div.body,div.sect');
    content.find('a.facet').each(function () {
      var link = $(this);
      var facets = link.parents('div.body,div.sect').children('div.contents').children('div.facets').children('div.facet');
      var visible = true;
      for (var i = 0; i < facets.length; i++) {
        var facet = facets.slice(i, i + 1);
        var facetvis = false;
        var inputs = facet.find('input.facet:checked');
        for (var j = 0; j < inputs.length; j++) {
          var input = inputs.slice(j, j + 1);
          var inputvis = false;
          var key = input.attr('data-facet-key');
          var values = input.attr('data-facet-values').split(' ');
          for (var k = 0; k < values.length; k++) {
            if (link.is('a[data-facet-' + key + ' ~= "' + values[k] + '"]')) {
              inputvis = true;
              break;
            }
          }
          if (inputvis) {
            facetvis = true;
            break;
          }
        }
        if (!facetvis) {
          visible = false;
          break;
        }
      }
      if (!visible)
        link.hide('fast');
      else
        link.show('fast');
    });
  });
});

$(document).ready(function () {
  $('div.mouseovers').each(function () {
    var contdiv = $(this);
    var width = 0;
    var height = 0;
    contdiv.find('img').each(function () {
      if ($(this).attr('data-yelp-match') == '')
        $(this).show();
    });
    contdiv.next('ul').find('a').each(function () {
      var mlink = $(this);
      mlink.hover(
        function () {
          var offset = contdiv.offset();
          mlink.find('img').css({left: offset.left, top: offset.top, zIndex: 10});
          mlink.find('img').fadeIn('fast');
        },
        function () {
          mlink.find('img').fadeOut('fast');
        }
      );
    });
  });
});
