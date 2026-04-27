#!/usr/bin/env python3
"""Ejecuta una consulta SQL contra Oracle usando oracledb en modo Thin."""
import json
import sys

import oracledb


def main():
    params = json.loads(sys.argv[1])
    conn = oracledb.connect(
        user=params["user"],
        password=params["password"],
        dsn=f"{params['host']}:{params['port']}/{params['service']}",
    )
    binds = params.get("binds", {})
    with conn.cursor() as cur:
        cur.execute(params["query"], binds)
        if cur.description:
            columns = [col[0] for col in cur.description]
            rows = [dict(zip(columns, row)) for row in cur.fetchall()]
        else:
            conn.commit()
            rows = []
    conn.close()
    print(json.dumps(rows, default=str))


if __name__ == "__main__":
    main()
