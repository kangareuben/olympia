from . import HiveQueryToFileCommand


class Command(HiveQueryToFileCommand):
    """Query the "download counts" requests from HIVE, save them to disk.

    The data stored locally will then be processed by the
    download_counts_from_file.py script.

    Usage:
    ./manage.py download_counts_from_hive <folder> --date YYYY-MM-DD

    If no date is specified, the default is the day before.
    If not folder is specified, the default is "hive_results". This folder is
    located in <settings.NETAPP_STORAGE>/tmp.

    Example row:

    2014-07-01	1	100157	search

    """
    help = __doc__
    filename = 'download_counts.hive'
    query = """
        SELECT
            ds,
            count(1),
            split(request_url,'/')[4],
            parse_url(concat('http://www.a.com', request_url), 'QUERY', 'src')
        FROM v2_raw_logs
        WHERE
            domain='addons.mozilla.org' AND
            ds='{day}' AND
            request_url LIKE '/%/downloads/file/%' AND

            {ip_filtering}

        GROUP BY
            ds,
            split(request_url,'/')[4],
            parse_url(concat('http://www.a.com', request_url), 'QUERY', 'src')
        {limit}
    """
