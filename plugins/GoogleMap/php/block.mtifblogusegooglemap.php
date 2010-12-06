<?php
function smarty_block_mtifblogusegooglemap ( $args, $content, &$ctx, &$repeat ) {
    $blog_id = $ctx->stash( 'blog_id' );
    if ( $blog_id ) {
        $config = $ctx->mt->db->fetch_plugin_data( 'googlemap', "configuration:blog:$blog_id" );
        $use_googlemap = $config[ 'use_googlemap' ];
        if ( $use_googlemap ) {
            return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, 1 );
        }
    }
    return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, 0 );
}
?>