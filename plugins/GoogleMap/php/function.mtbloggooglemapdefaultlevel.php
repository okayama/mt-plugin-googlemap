<?php
function smarty_function_mtbloggooglemapdefaultlevel ( $args, &$ctx ) {
    $blog_id = $ctx->stash( 'blog_id' );
    if ( $blog_id ) {
        $config = $ctx->mt->db->fetch_plugin_data( 'googlemap', "configuration:blog:$blog_id" );
    } else {
        $config = $ctx->mt->db->fetch_plugin_data( 'googlemap', "configuration" );
    }
    return $config[ 'default_level' ];
}
?>
