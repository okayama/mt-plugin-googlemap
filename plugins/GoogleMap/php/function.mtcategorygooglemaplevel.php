<?php
function smarty_function_mtcategorygooglemaplevel ( $args, &$ctx ) {
    $category = $ctx->stash( 'category' );
    $category_level = $category[ 'category_level' ];
    if ( $category_level ) {
        return $category_level;
    }
    return '';
}
?>
