package MT::Plugin::GoogleMap;
use strict;
use MT;
use MT::Plugin;

our $VERSION = '1.12';
our $SCHEMA_VERSION = '0.974';

use base qw( MT::Plugin );

###################################### Init Plugin #####################################

my $plugin = MT::Plugin::GoogleMap->new( {
    id => 'GoogleMap',
    key => 'googlemap',
    description => '<MT_TRANS phrase=\'_PLUGIN_DESCRIPTION\'>',
    name => 'GoogleMap',
    author_name => 'okayama',
    author_link => 'http://weeeblog.net/',
    version => $VERSION,
    schema_version => $SCHEMA_VERSION,
    l10n_class => 'GoogleMap::L10N',
    system_config_template => 'googlemap_config.tmpl',
    blog_config_template => 'googlemap_config_blog.tmpl',
    settings => new MT::PluginSettings( [
        [ 'googlemap_api_key', { Default => '' } ],
        [ 'use_googlemap', { Default => 1 } ],
        [ 'default_lat', { Default => '35.658629995310946' } ],
        [ 'default_lon', { Default => '139.74546879529953' } ],
        [ 'default_level', { Default => 12 } ],
    ] ),
} );

MT->add_plugin( $plugin );

sub init_registry {
    my $plugin = shift;
    $plugin->registry( {
        object_types => {
            'entry' => {
                'lat' => 'text',
                'lon' => 'text',
            },
            'category' => {
                'lat' => 'text',
                'lon' => 'text',
                'level' => 'text',
            },
        },
        callbacks => {
            'MT::App::CMS::template_param.edit_entry',
                => \&_cb_tp_edit_entry,
            'MT::App::CMS::template_param.edit_category',
                => \&_cb_tp_edit_category,
#             'MT::App::CMS::template_source.header',
#                 => \&_cb_ts_header,
            'MT::App::CMS::template_param.header',
                => \&_cb_tp_header,
            'api_post_save.entry',
                => \&_api_post_save_entry,
        },
        tags => {
            block => {
                'IfBlogUseGoogleMap?' => \&_hdlr_if_blog_use_google_map,
            },
            function => {
                'GoogleMapApiKey' => \&_hdlr_googlemap_api_key,
                'GoogleMapURL' => \&_hdlr_googlemap_url,
                'BlogGoogleMapDefaultLat' => \&_hdlr_blog_googlemap_default_lat,
                'BlogGoogleMapDefaultLon' => \&_hdlr_blog_googlemap_default_lon,
                'BlogGoogleMapDefaultLevel' => \&_hdlr_blog_googlemap_default_level,
                'CategoryGoogleMapLat' => \&_hdlr_category_googlemap_lat,
                'CategoryGoogleMapLon' => \&_hdlr_category_googlemap_lon,
                'CategoryGoogleMapLevel' => \&_hdlr_category_googlemap_level,
                'EntryGoogleMapLat' => \&_hdlr_entry_googlemap_lat,
                'EntryGoogleMapLon' => \&_hdlr_entry_googlemap_lon,
            },
         }
   } );
}

######################################## callbacks ########################################

# _api_post_save_entry
# save Lat and Lon
sub _api_post_save_entry {
    my ( $cb, $app, $entry, $orig ) = @_;
    my $blog_id = $app->param( 'blog_id' );
    unless ( $blog_id ) {
        $blog_id = $entry->blog_id;
    }
    return 1 unless $plugin->get_config_value( 'use_googlemap', 'blog:' . $blog_id );

    $entry->lat( $app->param( 'lat' ) );
    $entry->lon( $app->param( 'lon' ) );
    $entry->save or return $app->error( $app->translate(
                                            "Saving [_1] failed: [_2]", $entry->class_label,
                                            $entry->errstr
                                        )
                                      );
1;
}

sub _cb_tp_edit_entry {
    my ( $cb, $app, $param, $tmpl ) = @_;
    my $blog_id = $app->param( 'blog_id' );
    return 1 unless $plugin->get_config_value( 'use_googlemap', 'blog:' . $blog_id );

    my $default_lat = $plugin->get_config_value( 'default_lat', 'blog:' . $blog_id );
    my $default_lon = $plugin->get_config_value( 'default_lon', 'blog:' . $blog_id );
    my $default_level_setting = $plugin->get_config_value( 'default_level', 'blog:' . $blog_id );
    $$param{ default_lat } = $default_lat;
    $$param{ default_lon } = $default_lon;
    $$param{ default_level_setting } = $default_level_setting;
    
    my ( $pointer_field, $nodeset );
    $pointer_field = $tmpl->getElementById( 'tags' );

    # set map
    $nodeset = $tmpl->createElement( 'app:setting', { id => 'googlemap-map',
                                                      label => $plugin->translate( 'Map.' ),
                                                      required => 0,
                                                      label_class => 'top-label',
                                                    },
                                   );
    $nodeset->innerHTML( &_tmpl_edit_entry_map_field() );
    $tmpl->insertBefore( $nodeset, $pointer_field );

    # set point field
    $nodeset = $tmpl->createElement( 'app:setting', { id => 'point',
                                                      label => $plugin->translate( 'Point.' ),
                                                      required => 0,
                                                      label_class => 'top-label',
                                                    },
                                   );
    $nodeset->innerHTML( &_tmpl_edit_entry_point_field() );
    $tmpl->insertBefore( $nodeset, $pointer_field );

    # set street view
    $nodeset = $tmpl->createElement( 'app:setting', { id => 'googlemap-street_view',
                                                      label => $plugin->translate( 'Street View.' ),
                                                      required => 0,
                                                      label_class => 'top-label',
                                                    },
                                   );
    $nodeset->innerHTML( &_tmpl_edit_entry_street_view_field() . &_tmpl_header_googlemap_script );
    $tmpl->insertBefore( $nodeset, $pointer_field );
1;
}

sub _cb_tp_edit_category {
    my ( $cb, $app, $param, $tmpl ) = @_;
    my $blog_id = $app->param( 'blog_id' );
    return 1 unless $plugin->get_config_value( 'use_googlemap', 'blog:' . $blog_id );

    my $default_lat = $plugin->get_config_value( 'default_lat', 'blog:' . $blog_id );
    my $default_lon = $plugin->get_config_value( 'default_lon', 'blog:' . $blog_id );
    my $default_level_setting = $plugin->get_config_value( 'default_level', 'blog:' . $blog_id );
    $$param{ default_lat } = $default_lat;
    $$param{ default_lon } = $default_lon;
    $$param{ default_level_setting } = $default_level_setting;
    
    my ( $pointer_field, $nodeset );
    $pointer_field = $tmpl->getElementById( 'description' );

    # set map
    $nodeset = $tmpl->createElement( 'app:setting', { id => 'googlemap-setting',
                                                      label => $plugin->translate( 'Google Map' ),
                                                      required => 0,
                                                    },
                                   );
    $nodeset->innerHTML( &_tmpl_edit_category_googlemap_setting() );
    $tmpl->insertAfter( $nodeset, $pointer_field );
1;
}

# sub _cb_ts_header {
#     my ( $cb, $app, $tmpl ) = @_;
#     my $blog_id = $app->param( 'blog_id' );
#     return 1 unless $plugin->get_config_value( 'use_googlemap', 'blog:' . $blog_id );
#     return 1 unless $app->mode eq 'view';
#     return 1 unless $app->param( '_type' ) eq 'entry' || $app->param( '_type' ) eq 'page';
# 
#     my $pointer = '</head>';
#     my $q_pointer = quotemeta( $pointer );
#     my $add_map = &_tmpl_header_googlemap_script();
#     $$tmpl =~ s/$q_pointer/$add_map$pointer/;
#     $$tmpl =~ s/<body/<body onload="javascript:mapLoad();" onUnload="javascript:GUnload();"/;
# 1;
# }

sub _cb_tp_header {
    my ( $cb, $app, $param, $tmpl ) = @_;
    my $blog_id = $app->param( 'blog_id' );
    return 1 unless $plugin->get_config_value( 'use_googlemap', 'blog:' . $blog_id );

    my $default_lat = $plugin->get_config_value( 'default_lat', 'blog:' . $blog_id );
    my $default_lon = $plugin->get_config_value( 'default_lon', 'blog:' . $blog_id );
    my $default_level_setting = $plugin->get_config_value( 'default_level', 'blog:' . $blog_id );
    $$param{ default_lat } = $default_lat;
    $$param{ default_lon } = $default_lon;
    $$param{ default_level_setting } = $default_level_setting;
1;
}

######################################## tags ########################################

sub _hdlr_googlemap_url {
    my ( $ctx, $args, $cond ) = @_;
    my $lang = MT->current_language;
    if ( $lang eq 'ja' ) {
        return 'http://maps.google.co.jp/';
    } else {
        return 'http://maps.google.com/';
    }
}

sub _hdlr_if_blog_use_google_map {
    my ( $ctx, $args, $cond ) = @_;
    return 0 unless $ctx->stash( 'blog' );
    my $use_googlemap = $plugin->get_config_value( 'use_googlemap', 'blog:' . $ctx->stash( 'blog' )->id );
    if ( $use_googlemap ) {
        return 1;
    }
    return 0;
}

sub _hdlr_googlemap_api_key {
    my $get_from = 'system';
    my $googlemap_api_key = $plugin->get_config_value( 'googlemap_api_key', $get_from );
    if ( $googlemap_api_key ) {
        return $googlemap_api_key;
    }
    return '';
}

sub _hdlr_blog_googlemap_default_lat {
    my ( $ctx, $args, $cond ) = @_;
    return '' unless $ctx->stash( 'blog' );
    my $default_lat = $plugin->get_config_value( 'default_lat', 'blog:' . $ctx->stash( 'blog' )->id );
    if ( $default_lat ) {
        return $default_lat;
    }
    return '';
}

sub _hdlr_blog_googlemap_default_lon {
    my ( $ctx, $args, $cond ) = @_;
    return '' unless $ctx->stash( 'blog' );
    my $default_lon = $plugin->get_config_value( 'default_lon', 'blog:' . $ctx->stash( 'blog' )->id );
    if ( $default_lon ) {
        return $default_lon;
    }
    return '';
}

sub _hdlr_blog_googlemap_default_level {
    my ( $ctx, $args, $cond ) = @_;
    return '' unless $ctx->stash( 'blog' );
    my $default_level = $plugin->get_config_value( 'default_level', 'blog:' . $ctx->stash( 'blog' )->id );
    if ( $default_level ) {
        return $default_level;
    }
    return '';
}

sub _hdlr_category_googlemap_lat {
    my ( $ctx, $args, $cond ) = @_;
    my $category = ( $_[0]->stash( 'category' ) || $_[0]->stash( 'archive_category' ) )
                        or return $_[0]->error( MT->translate(
                            "You used an [_1] tag outside of the proper context.",
                            '<$MT' . $_[0]->stash( 'tag' ) . '$>' ) );
    my $lat = $category->lat;
    if ( $lat ) {
        return $lat;
    }
    return '';
}

sub _hdlr_category_googlemap_lon {
    my ( $ctx, $args, $cond ) = @_;
    my $category = ( $_[0]->stash( 'category' ) || $_[0]->stash( 'archive_category' ) )
                        or return $_[0]->error( MT->translate(
                            "You used an [_1] tag outside of the proper context.",
                            '<$MT' . $_[0]->stash( 'tag' ) . '$>' ) );
    my $lon = $category->lon;
    if ( $lon ) {
        return $lon;
    }
    return '';
}

sub _hdlr_category_googlemap_level {
    my ( $ctx, $args, $cond ) = @_;
    my $category = ( $_[0]->stash( 'category' ) || $_[0]->stash( 'archive_category' ) )
                        or return $_[0]->error( MT->translate(
                            "You used an [_1] tag outside of the proper context.",
                            '<$MT' . $_[0]->stash( 'tag' ) . '$>' ) );
    my $level = $category->level;
    if ( $level ) {
        return $level;
    }
    return '';
}

sub _hdlr_entry_googlemap_lat {
    my ( $ctx, $args, $cond ) = @_;
    my $entry = $ctx->stash( 'entry' ) or return $ctx->_no_entry_error( '<$MT' . $_[0]->stash( 'tag' ) . '$>' );
    if ( $entry->lat ) {
        return $entry->lat;
    }
    return '';
}

sub _hdlr_entry_googlemap_lon {
    my ($ctx, $args, $cond) = @_;
    my $entry = $ctx->stash( 'entry' ) or return $ctx->_no_entry_error( '<$MT' . $_[0]->stash( 'tag' ) . '$>' );
    if ( $entry->lon ) {
        return $entry->lon;
    }
    return '';
}

######################################## templates ########################################

# header.tmpl

sub _tmpl_header_googlemap_script {
    return<<'MTML';
        <__trans_section component="googlemap">
            <script src="<$MTGoogleMapURL$>maps?file=api&v=2&key=<$mt:googlemapapikey$>" type="text/javascript" charset="utf-8"></script>
            <script src="http://www.google.com/uds/api?file=uds.js&v=1.0&key=<$mt:googlemapapikey$>" type="text/javascript"></script>
            <script src="http://www.google.com/uds/solutions/localsearch/gmlocalsearch.js" type="text/javascript"></script>
            <style type="text/css">
                @import url( "http://www.google.com/uds/css/gsearch.css" );
                @import url( "http://www.google.com/uds/solutions/localsearch/gmlocalsearch.css" );
            </style>
            <script type="text/javascript">
            //<![CDATA[
            <mt:setvarblock name="center_lat"><mt:if name="lat"><mt:var name="lat"><mt:else><mt:var name="default_lat"></mt:if></mt:setvarblock>
            <mt:setvarblock name="center_lon"><mt:if name="lon"><mt:var name="lon"><mt:else><mt:var name="default_lon"></mt:if></mt:setvarblock>
            var mapId = "gMap";
            var streetViewId = "gView";
            var gmap;
            var gview;
            
            // show map
            function mapLoad () {
                if ( GBrowserIsCompatible() ) {
                    gmap = new GMap2( document.getElementById( mapId ) );
                    gmap.setCenter( new GLatLng( <mt:var name="center_lat">, <mt:var name="center_lon"> ), <mt:var name="default_level_setting"> );
                    gmap.addControl( new GLargeMapControl() );
                    gmap.addControl( new GMapTypeControl() );
                    gmap.addControl( new GOverviewMapControl() );
                    gmap.addControl( new google.maps.LocalSearch() );

                    // show cross
                    var cross = document.createElement( "div" );
                    var crossWidth = 23;	// cross width(img)
                    var crossHeight = 23;	// cross height(img)
                    var mapWidth = parseInt( gmap.getContainer().style.width );
                    var mapHeight = parseInt( gmap.getContainer().style.height );
                    var x = ( mapWidth - crossWidth ) / 2;	// cross center(x)
                    var y = ( mapHeight - crossHeight ) / 2;  // cross center(y)
                    cross.style.position = "absolute";
                    cross.style.top = y+"px";
                    cross.style.left = x+"px";
                    cross.style.backgroundImage = "url( <mt:staticwebpath>plugins/GoogleMap/images/center.gif )";
                    cross.style.width = crossWidth+"px";
                    cross.style.height = crossHeight+"px";
                    cross.style.opacity = 0.5;
                    gmap.getContainer().appendChild( cross );
                    viewLoad( <mt:var name="center_lat">, <mt:var name="center_lon"> );
                    
                    // event listener
                    GEvent.addListener( gmap, 'click', mapClickEvent );
                    GEvent.addListener( gmap, 'move', mapMoveEvent );
                }
            }
            
            // show street view
            function viewLoad() {
                targetPoint  = new GLatLng( <mt:var name="center_lat">, <mt:var name="center_lon"> );
                panoramaOptions  = { latlng:targetPoint };
                gview = new GStreetviewPanorama( document.getElementById( streetViewId ), panoramaOptions );
                    
                // event listener
                GEvent.addListener( gview, "error", handlePanoramaError );
                GEvent.addListener( gview, "initialized", handleViewInitialized );
            }
            
            // map event
            function mapInit( lat, lon ) {
                if ( ! lat ) {
                    lat = <mt:var name="center_lat">;
                }
                if ( ! lon ) {
                    lon = <mt:var name="center_lon">;
                }
                map.setCenter( lat, lon );
            }
            
            function mapMoveEvent() {
                var xy = gmap.getCenter();
                if ( document.getElementById( "lat" ) ) {
                    document.getElementById( "lat" ).value = xy.lat();
                }
                if ( document.getElementById( "lon" ) ) {
                    document.getElementById( "lon" ).value = xy.lng();
                }
                viewInit( xy.lat(), xy.lng() );
            }
            
            function mapClickEvent( overlay, point ){
                gmap.setCenter( point );
                gview.setLocationAndPOV( point );
            }
            
            // street view event
            function viewInit( lat, lon ) {
                if ( ! lat ) {
                    lat = <mt:var name="center_lat">;
                }
                if ( ! lon ) {
                    lon = <mt:var name="center_lon">;
                }
                targetPoint  = new GLatLng( lat, lon );
                gview.setLocationAndPOV( targetPoint );
            }
            
            function handleViewInitialized( location ) {
                gmap.setCenter(location.latlng);
            }
                
            function handlePanoramaError( errorCode ) {
              if ( errorCode == 600 ) {
                document.getElementById( streetViewId ).innerHTML = '<p style="color:red;">You cannot use street view in this area.</p>';
                return;
              }
              if ( errorCode == 603 ) {
                document.getElementById( streetViewId ).innerHTML = '<p style="color:red;">You cannnot use streew view by this browser.</p>';
                return;
              }
            }
            mapLoad();
            //]]>
            </script>
        </__trans_section> 
MTML
}

# edit_category.tmpl

sub _tmpl_edit_category_googlemap_setting {
    return<<'MTML';
        <__trans_section component="googlemap">
            <label for="lat" style="font-weight:bold;display:block;margin-bottom:3px;color:#333;"><__trans phrase="Default Lat."></label>
            <div class="textarea-wrapper" style="margin-bottom:10px;">
                <input name="lat" id="lat" class="full-width" maxlength="100" value="<mt:if name="lat"><mt:var name="lat"><mt:else><mt:var name="default_lat"></mt:if>" class="wide" />
            </div>
            <label for="lon" style="font-weight:bold;display:block;margin-bottom:3px;color:#333;"><__trans phrase="Default Lon."></label>
            <div class="textarea-wrapper" style="margin-bottom:10px;">
                <input name="lon" id="lon" class="full-width" maxlength="100" value="<mt:if name="lon"><mt:var name="lon"><mt:else><mt:var name="default_lon"></mt:if>" class="wide" />
            </div>
            <label for="level" style="font-weight:bold;display:block;margin-bottom:3px;color:#333;"><__trans phrase="Level."></label>
            <mt:unless name="level">
                <mt:var name="default_level_setting" setvar="level">
            </mt:unless>
            <select name="level" id="level" style="width:550px">
                <option value="1"<mt:if name="level" eq="1"> selected="selected"</mt:if>>1</option>
                <option value="2"<mt:if name="level" eq="2"> selected="selected"</mt:if>>2</option>
                <option value="3"<mt:if name="level" eq="3"> selected="selected"</mt:if>>3</option>
                <option value="4"<mt:if name="level" eq="4"> selected="selected"</mt:if>>4</option>
                <option value="5"<mt:if name="level" eq="5"> selected="selected"</mt:if>>5</option>
                <option value="6"<mt:if name="level" eq="6"> selected="selected"</mt:if>>6</option>
                <option value="7"<mt:if name="level" eq="7"> selected="selected"</mt:if>>7</option>
                <option value="8"<mt:if name="level" eq="8"> selected="selected"</mt:if>>8</option>
                <option value="9"<mt:if name="level" eq="9"> selected="selected"</mt:if>>9</option>
                <option value="10"<mt:if name="level" eq="10"> selected="selected"</mt:if>>10</option>
                <option value="11"<mt:if name="level" eq="11"> selected="selected"</mt:if>>11</option>
                <option value="12"<mt:if name="level" eq="12"> selected="selected"</mt:if>>12</option>
                <option value="13"<mt:if name="level" eq="13"> selected="selected"</mt:if>>13</option>
                <option value="14"<mt:if name="level" eq="14"> selected="selected"</mt:if>>14</option>
                <option value="15"<mt:if name="level" eq="15"> selected="selected"</mt:if>>15</option>
            </select>
        </__trans_section>        
MTML
}

# edit_entry.tmpl

sub _tmpl_edit_entry_map_field {
    return<<'MTML';
        <__trans_section component="googlemap">
            <div id="gMap" style="width: 580px; height: 450px; border: 1px solid #ccc;"></div>
        </__trans_section>
MTML
}

sub _tmpl_edit_entry_point_field {
    return<<'MTML';
        <__trans_section component="googlemap">
            <div class="textarea-wrapper" style="padding: 5px 5px 10px 5px;">
                <__trans phrase="Lat."><br />
                <input type="text" name="lat" id="lat" class="full-width" value="<mt:if name="lat"><mt:var name="lat"><mt:else><mt:var name="default_lat"></mt:if>" style="border: 1px solid #ccc; margin-bottom: 5px;" /><br />
                <__trans phrase="Lon."><br />
                <input type="text" name="lon" id="lon" class="full-width" value="<mt:if name="lon"><mt:var name="lon"><mt:else><mt:var name="default_lon"></mt:if>" style="border: 1px solid #ccc;" />
            </div>
        </__trans_section>
MTML
}

sub _tmpl_edit_entry_street_view_field {
    return<<'MTML';
        <__trans_section component="googlemap">
            <div id="gView" style="width: 580px; height: 350px; border: 1px solid #ccc;"></div>
        </__trans_section>
MTML
}

1;