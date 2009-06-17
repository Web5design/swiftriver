var mapstraction, drawControls;
var last_updated = null;
var filters = "";
var state = ""; // used for autoZoom toggling
var load_url = "";
function remoteLoad(file, handler) {
	jsonp_mapping(file, handler);
}

function jsonp_mapping(url,callback, query)
{ 
    if(url == null)
      return null;
      
    if (url.indexOf("?") > -1)
        url += "&callback=" 
    else
        url += "?callback=" 
    url += callback + "&";
    if (query)
        url += encodeURIComponent(query) + "&";   
    url += new Date().getTime().toString(); // prevent caching        
    
    var script = document.createElement("script");        
    script.setAttribute("src",url);
    script.setAttribute("type","text/javascript");                
    document.body.appendChild(script);
}

// Adds a semi-opaque gray overlay on the map to make the markers pop out more
function fadeMap() {
    mapstraction.getMap().addOverlay(new GPolygon([new GLatLng(-85,180.000001),new GLatLng(85,180.000001),new GLatLng(85,330),new GLatLng(-85,330)],null,0,0,"#d0d0d0",0.4));
    mapstraction.getMap().addOverlay(new GPolygon([new GLatLng(-85,0.000001),new GLatLng(85,0.000001),new GLatLng(85,330),new GLatLng(-85,330)],null,0,0,"#d0d0d0",0.4));
    mapstraction.getMap().addOverlay(new GPolygon([new GLatLng(-85,0.000001),new GLatLng(85,0.000001),new GLatLng(85,180),new GLatLng(-85,180)],null,0,0,"#d0d0d0",0.4));
    // mapstraction.getMap().addOverlay(new GPolygon([new GLatLng(20,180.000001),new GLatLng(70,180.000001),new GLatLng(70,330),new GLatLng(-20,330)],null,0,0,"#d0d0d0",0.4));
}
map_initialized = false;
function initMapJS(url,map_filters){
  map_initialized = true;
    // initialise the map with your choice of API
    mapstraction = new Mapstraction('map','google');
    filters = map_filters;

    jQuery("#filter_state").change(function () { 
        state = jQuery("#filter_state").val();
        updateState(state);
    });
    // display the map centered on a latitude and longitude (Google zoom levels)
    var myPoint = new LatLonPoint(32.787275,54.316406);
    mapstraction.setCenterAndZoom(myPoint, 6);
    mapstraction.addControls({zoom: 'small'});

    fadeMap();
    last_updated = new Date().toISO8601String();
    jQuery("#last_updated").text(last_updated);
    // setInterval("updateMap();",60000);
    // if(url != null) { 
    //   remoteLoad(url,"")
    // }
}
var current_page = 1;
function updateState(state, page) {
    var current_filter = "";
    if(page == null)
        page = 1;
    else {
        jQuery("#page_" + current_page).removeClass("current");
        jQuery("#page_" + page).addClass("current");        
    }

    hideMessage();
    current_page = page;
    mapstraction.removeAllMarkers();
    fadeMap();
    gmarkers = [];
    filters = current_filter = "state=" + state;
        
    jQuery("#update_status").show();
    if(state == null)
        jQuery.getJSON("/feeds/" + page +".json", "");    
    else
        jQuery.getJSON("/feeds/state/"+state+"/" + page +".json", "");
    return false;
}
function updateMap(url,map_filter,view_state) {
    var current_filter = "";
    hideMessage();
    state = view_state;
    if(map_filter != "" || map_filter != null) {
        mapstraction.removeAllMarkers();
        fadeMap();
        gmarkers = [];
        filters = current_filter = map_filter;
    } else {
        current_filter = "dtstart="+last_updated+"&" + filters;
    }
        
    jQuery("#update_status").show();
    // jQuery.getJSON("/reports.json?"+current_filter+"&page=1&count=200&callback=updateJSON", "");
    jQuery.getJSON(url, "");
    return false;
}
function showMessage(message) {
    jQuery("#message").text(message);
    jQuery("#message").show();
}
function hideMessage(message) {
    jQuery("#message").text("");
    jQuery("#message").hide();
}
function updateJSON(response) {
    var num_markers = mapstraction.addJSON(response);
    if(num_markers <= 0)
        showMessage("Sorry - no reports with this filter.");

    if( (state != null || state != "") && state != "us" ) {
        mapstraction.autoCenterAndZoom();
    }
    else {
      var myPoint = new LatLonPoint(32.787275,54.316406);
      mapstraction.setCenterAndZoom(myPoint, 6);      
    }
    mapstraction.autoCenterAndZoom();
    
    last_updated = new Date().toISO8601String();
    jQuery("#last_updated").text(last_updated);    
    jQuery("#update_status").hide();
}

var gmarkers = []
Mapstraction.prototype.addJSON = function(features) {
// var features = eval('(' + json + ')');
var map = this.maps[this.api];
var html = "";
var polyline;
var item;
var asset_server = "http://assets0.mapufacture.com";
var num_markers = 0;
for (var i = 0; i < features.length; i++) {
  item = features[i];
  if(item != null && item.location != null && item.location.location.point != null) {
    switch(item.location.location.point.type) {
      case "Point":
      var icon_size; var icon;
      if(item.score != null) {
        if(item.score <= 30)
        icon = "/images/score_bad.png";
        else if (item.score <= 70)
        icon = "/images/score_medium.png";
        else
        icon = "/images/score_good.png";
      }
      else if(item.icon == "" || item.icon == null){
        icon = "/images/gmaps/pushpins/webhues/159.png" 
        icon_size = [10,17];

      } else {
        icon = item.icon
      }
      icon_scale = 18
      if(icon_scale > 24)
        icon_scale = 24
      icon_size = [icon_scale,icon_scale];

      html = item.display_html;

      this.addMarkerWithData(new Marker(new LatLonPoint(item.location.location.point.coordinates[1],item.location.location.point.coordinates[0])),{
        infoBubble : html, 
        label : item.name, 
        date : "new Date(\""+item.created_at+"\")", 
        iconShadow : "http://mapufacture.com/images/providers/blank.png",
        marker : item.id, 
        date : "new Date(\""+item.date+"\")", 
        iconShadowSize : [0,0],
        icon : icon,
        iconSize : icon_size, 
        category : item.source_id, 
        draggable : false, 
        hover : false});
        num_markers += 1;
        break;
        case "Polygon":
        var points = [];
        polyline = new Polyline(points);
        this.addPolylineWithData(polyline,{fillColor : item.poly_color,date : "new Date(\""+item.date+"\")",category : item.source_id,width : item.line_width,opacity : item.line_opacity,color : item.line_color, polygon : true});					
        default:
        // console.log("Geometry: " + features.items[i].geometry.type);
      }
    }
  }
    return num_markers;
}

