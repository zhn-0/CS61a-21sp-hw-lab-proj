
passphrase = '*** PASSPHRASE HERE ***'


def survey(p):
    """
    You do not need to understand this code.
    '9c557774afa3f7b5670f10a5ca54be0eedb8384a780375daa0340b45'
    >>> survey(passphrase)
    '0a482bce4722c8cced08479fda380c07ed4a3d664ee1bee9c90b6ed9'
    """
    import hashlib
    return hashlib.sha224(p.encode('utf-8')).hexdigest()
