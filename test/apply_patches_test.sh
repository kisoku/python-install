. ./test/helper.sh

PATCHES=("https://totallyboguslocation.null/test.diff")

function setUp()
{
	SRC_DIR="$PWD/test/src"
	PYTHON_SRC_DIR="Python-2.6.8"

	mkdir -p "$SRC_DIR/$PYTHON_SRC_DIR"
}

function test_apply_patches()
{
	echo "
diff -Naur $PYTHON_SRC_DIR.orig/test $PYTHON_SRC_DIR/test
--- $PYTHON_SRC_DIR.orig/test 1970-01-01 01:00:00.000000000 +0100
+++ $PYTHON_SRC_DIR/test  2013-08-02 20:57:08.055843749 +0200
@@ -0,0 +1 @@
+patch
" 	> "$SRC_DIR/$PYTHON_SRC_DIR/test.diff"

	cd "$SRC_DIR/$PYTHON_SRC_DIR"
	apply_patches >/dev/null
	cd $OLDPWD

	assertTrue "did not apply downloaded patches" \
		   '[[ -f "$SRC_DIR/$PYTHON_SRC_DIR/test" ]]'
}

function tearDown()
{
	echo ''
	#rm -r "$SRC_DIR/$PYTHON_SRC_DIR"
}

SHUNIT_PARENT=$0 . $SHUNIT2
