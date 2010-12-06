<?php
function smarty_function_mtcategorygooglemaplon ( $args, &$ctx ) {
    $category = $ctx->stash( 'category' );
    $category_lon = $category[ 'category_lon' ];
    if ( $category_lon ) {
        return $category_lon;
    }
    return '';
}
?>
