# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=hatchling
PYTHON_COMPAT=( python3_{12..15} )

inherit distutils-r1 optfeature pypi

DESCRIPTION="Simple integration of Flask and WTForms, including CSRF protection"
HOMEPAGE="
	https://github.com/wtforms/flask-wtf
	https://pypi.org/project/Flask-WTF/
"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64 ~arm64"

RDEPEND="
	dev-python/flask[${PYTHON_USEDEP}]
	dev-python/itsdangerous[${PYTHON_USEDEP}]
	dev-python/wtforms[${PYTHON_USEDEP}]
"

# The email extra (dev-python/email-validator) is not pulled in: it only backs
# wtforms' EmailField validator, which nothing in this overlay's consumers uses.
EPYTEST_PLUGINS=()
distutils_enable_tests pytest

pkg_postinst() {
	optfeature "email address validation in forms" dev-python/email-validator
}
