<?php
function smarty_function_mtgooglemapapikey ( $args, &$ctx ) {
    $config = $ctx->mt->db->fetch_plugin_data( 'googlemap_api_key', "configuration" );
    return $config;
}
?>
