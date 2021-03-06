# rubocop:disable Metrics/ModuleLength
# rubocop:disable Metrics/MethodLength
# rubocop:disable Metrics/AbcSize
# rubocop:disable Style/MultilineTernaryOperator
# rubocop:disable Layout/SpaceInsideStringInterpolation
module MapHelper
  INITIAL_LATITUDE = 45.2671352
  INITIAL_LONGITUDE = 19.83354959999997
  INITIAL_ZOOM = 12
  GOOGLE_API_KEY = Rails.application.secrets.google_api_key

  # You need to provide input fields: `text_field` or `hidden_field` so they
  # will be updated in javascript callback.
  #  <%= f.text_field :latitude, id: 'latitude-input' %>
  #  <%= f.text_field :longitude, id: 'longitude-input' %>
  #  <%= edit_map f.object, "#latitude-input", "#longitude-input" %>
  #
  # If you are showing inside bootstrap tab or modal than you need to trigger
  # resize. If you do not have map object, you can trigger resize on window
  # google.maps.event.trigger(window, 'resize')
  # but the problem is when map is initialized to hidden element, than center is
  # on top right corner, so when you trigger resize, pin will be on top-right
  # We need to getCenter and call setCenter again after we trigger resize so I
  # did it using addDomListener on window object and fire that resize on modal
  # show:
  #
  # somewhere inside function initialize_google() {
  #        google.maps.event.addDomListener(window, "resize", function() {
  #          var center = map.getCenter();
  #          google.maps.event.trigger(map, "resize");
  #          map.setCenter(center);
  #          console.log('map resize');
  #        });
  # somewhere in your javascript/coffeescript:
  # $(document).on 'shown.bs.modal', ->
  #   window.dispatchEvent(new Event('resize'))
  #
  # This works but if you are destroying modal on hide (so it loads new content
  # based on response), than map will be destroyed too.
  #
  # $(document).on 'hidden.bs.modal', '.modal', ->
  #   $(this).removeData('bs.modal')
  #
  # If you have two nested modal-content than there is a problem that javascript
  # in modal response is run only once (you can put alert inside script and it
  # will be shown only first time modal is opened)
  # So you can not trigger initialize_google() from this page but only on modal
  # shown event. Good is that you do not need to trigger resize since we draw
  # map again:
  # $(document).on 'shown.bs.modal', '.modal', ->
  #   if this.innerHTML.indexOf('initialize_google') > -1
  #     initialize_google()
  def edit_map(object, latitude_input, longitude_input)
    if object.latitude
      latitude = object.latitude
      longitude = object.longitude
      zoom_level = 17
    else
      latitude = INITIAL_LATITUDE
      longitude = INITIAL_LONGITUDE
      zoom_level = INITIAL_ZOOM
    end
    address_id = "address-suggestion" # -#{SecureRandom.hex 3}"
    content = text_field_tag(
      address_id, nil, placeholder:
      I18n.t('write_address_than_move_marker'), size: 50
    )
    map_id = "preview-map" #-#{SecureRandom.hex 3}"
    content << content_tag(:div, nil, id: map_id, class: 'edit-map-container')
    content << %(
      <script>
        function updateFields(position) {
          $("#{latitude_input}").val(position.lat());
          $("#{longitude_input}").val(position.lng());
        }
        function initialize_google() {
          console.log('initialize_google edit_map #{Time.zone.now}');
          // https://wiki.openstreetmap.org/wiki/Google_Maps_Example
          var mapTypeIds = [];
          for(var type in google.maps.MapTypeId) {
           mapTypeIds.push(google.maps.MapTypeId[type]);
          }
          mapTypeIds.push("OSM");
          var map = new google.maps.Map(document.getElementById('#{map_id}'), {
            center: {lat: #{latitude}, lng: #{longitude} },
            zoom: #{zoom_level},
            mapTypeId: "OSM",
            mapTypeControlOptions: {
              mapTypeIds: mapTypeIds
            },
          });

          map.mapTypes.set("OSM", new google.maps.ImageMapType({
            getTileUrl: function(coord, zoom) {
              // See above example if you need smooth wrapping at 180th meridian
              return "http://tile.openstreetmap.org/" + zoom + "/" + coord.x + "/" + coord.y + ".png";
              },
            tileSize: new google.maps.Size(256, 256),
            name: "OpenStreetMap",
            maxZoom: 18,
          }));
          var autocomplete = new google.maps.places.Autocomplete(
            document.getElementById('#{address_id}'),
            { componentRestrictions: {country: 'rs'} }
          );
          var marker = new google.maps.Marker({
            map: map,
            anchorPoint: new google.maps.Point(0, -29),
            draggable: true,
            animation: google.maps.Animation.DROP,
            #{object.latitude.present? ?
              "position: {
                lat: #{latitude},
                lng: #{longitude},
              }," : '' }
          });
          autocomplete.bindTo('bounds', map);
          autocomplete.addListener('place_changed', function() {
            marker.setVisible(false);
            var place = autocomplete.getPlace();
            if (!place.geometry) {
             window.alert("#{I18n.t('autocomplete_contains_no_geometry')}");
             return;
            }
            // If the place has a geometry, then present it on a map.
            if (place.geometry.viewport) {
             map.fitBounds(place.geometry.viewport);
            } else {
             map.setCenter(place.geometry.location);
             map.setZoom(17);  // Why 17? Because it looks good.
            }
            marker.setPosition(place.geometry.location);
            marker.setVisible(true);
            updateFields(place.geometry.location);
            console.log('place_changed');
          });

          google.maps.event.addListener(marker, "dragend", function(e) {
            updateFields(marker.getPosition());
          });
        } // function initialize_google
      </script>
    ).html_safe
    content << async_load
  end

  # https://developers.google.com/maps/documentation/static-maps/intro
  def show_static_map(object, options = {})
    latitude = object.latitude
    longitude = object.longitude
    return "<div class='map-not-set'>Map position is not set</div>".html_safe unless latitude
    img_options = {}
    img_options[:class] = options[:class] if options[:class].present?
    url = "//maps.googleapis.com/maps/api/staticmap?"
    url += "size=70x70"
    # custom icon must be http:// not https://
    # markers=icon:http://developers.google.com/maps/documentation/javascript/examples/full/images/beachflag.png|
    url += "&markers=|#{latitude},#{longitude}"
    # you need to enable "Google Static Maps API"
    url += "&key=#{GOOGLE_API_KEY}"
    link_to "http://maps.google.com/?q=#{latitude},#{longitude}" do
      image_tag url, img_options
    end
  end

  def show_map(object, options = {})
    latitude = object.latitude
    longitude = object.longitude
    return "<div class='map-not-set'>Map position is not set</div>".html_safe unless latitude
    content = content_tag(:div, nil, id: 'preview-map', class: "show-map-container #{options[:class]}")
    content << %(
      <script>
        function initialize_google() {
          console.log('initialize_google show_map');
          var previewMapElement = document.getElementById('preview-map');
          var map = new google.maps.Map(previewMapElement, {
            center: {lat: #{latitude}, lng: #{longitude} },
            zoom: 17,
          });
          var marker = new google.maps.Marker({
            map: map,
            animation: google.maps.Animation.DROP,
            #{object.latitude.present? ?
              "position: {
                lat: #{latitude},
                lng: #{longitude},
              }," : '' }
          });
          $(previewMapElement).data('mapObject', map);
        } // function initialize_google
      </script>
    ).html_safe
    content << async_load
  end

  # all objects should have: name
  # optional: description_for_map, url_for_map, script_for_map
  def show_all_map(objects, options = {})
    data = objects.map do |object|
      next if !object.latitude.present? || !object.longitude.present?
      {
        position: {
          lat: object.latitude,
          lng: object.longitude,
        },
        name: object.name,
        description_for_map: object.description_for_map,
        url_for_map: object.respond_to?("url_for_map") ? object.url_for_map : '',
      }
    end.compact
    content = content_tag(:div, nil, id: 'preview-map', class: "show-all-map-container #{options[:class]}")
    content << %(
      <script>
        #{options[:script_for_map]}
        function initialize_google() {
          console.log('initialize_google show_all_map');
          var map = new google.maps.Map(document.getElementById('preview-map'), {
            center: {lat: #{INITIAL_LATITUDE}, lng: #{INITIAL_LONGITUDE}},
            zoom: #{INITIAL_ZOOM},
          });
          var data = #{data.to_json};
          var markers = [];
          var bounds = new google.maps.LatLngBounds();
          var infoWindow = new google.maps.InfoWindow({
            content: "<div><a href='' id='info-url'><h4></h4></a><div id='info-name'></div><p id='info-description'></p></div>"
          });
          for(var i = 0; i < data.length; i++ ) {
            var marker = new google.maps.Marker({
              animation: google.maps.Animation.DROP,
              position: data[i].position,
              name: data[i].name,
              description_for_map: data[i].description_for_map,
              url_for_map: data[i].url_for_map,
            });
            bounds.extend(marker.getPosition());
            markers[i] = marker;
            var interval = 1000 / (data.length + 1);
            setTimeout(dropMarker(i), i * interval);
            google.maps.event.addListener(marker, 'click', function() {
              infoWindow.open(map, this);
              $('#info-description').html(this.description_for_map);
              if (this.url_for_map) {
                $('#info-url').attr('href', this.url_for_map)
                .html('<h4>'+this.name+'</h4>');
                $('#info-name').html();
              } else {
                $('#info-name').html('<h4>'+this.name+'</h4>');
                $('#info-url').html();
              }
            });
          }
          map.fitBounds(bounds);
          function dropMarker(i) {
            return function() {
              markers[i].setMap(map);
            };
          }
        } // function initialize_google
      </script>
    ).html_safe
    content << async_load
  end

  private

  def async_load
    %(
      <script>
        // https://developers.google.com/maps/documentation/javascript/examples/map-simple-async
        function loadScript() {
          var script = document.createElement('script');
          script.type = 'text/javascript';
          script.src = 'https://maps.googleapis.com/maps/api/js?libraries=places' +
              '&key=#{GOOGLE_API_KEY}&callback=initialize_google';
          document.body.appendChild(script);
        }
        // http://stackoverflow.com/questions/9228958/how-to-check-if-google-maps-api-is-loaded
        if (typeof google === 'object' && typeof google.maps === 'object') {
          // it is loaded but we need to bind on newly created object
          initialize_google();
        } else {
          loadScript();
        }
      </script>
    ).html_safe
  end
end
