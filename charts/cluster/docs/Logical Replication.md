Logical Replication
===================

This chart supports CNPG's logical replication capabilities.

Logical replication allows you to replicate data between two separate PostgreSQL clusters.

Requirements
------------

- **Publisher cluster**: Must have `wal_level: logical` set in `cluster.postgresql.parameters`. CNPG enables this by default.
- **Subscriber cluster**: Table schemas must exist before the subscription becomes active (DDL is not replicated)
- **Connection user**: Must have REPLICATION privilege on the publisher

Privilege Requirements
----------------------

**For publications:**
- `FOR ALL TABLES` requires superuser (or `pg_publication_owner` role in PostgreSQL 15+)
- For specific tables, only table ownership is required

**For subscriptions:**
- Requires superuser or `pg_create_subscription` role (PostgreSQL 16+)

**For the connection from subscriber to publisher:**
- The connecting user must have REPLICATION privilege

Publisher Cluster Configuration
-------------------------------

The publisher cluster creates a publication that defines what data to replicate.

```yaml
type: postgresql
mode: standalone

cluster:
  instances: 1
  enableSuperuserAccess: true
  postgresql:
    parameters:
      wal_level: logical
      max_replication_slots: "10"
      max_wal_senders: "10"

publications:
  - name: all-tables
    dbname: app
    target:
      allTables: true
    publicationReclaimPolicy: delete
```

### Publication Target Options

**All tables in the database:**
```yaml
publications:
  - name: all-tables
    dbname: app
    target:
      allTables: true
```

**Specific tables only:**
```yaml
publications:
  - name: users-only
    dbname: app
    target:
      objects:
        - table:
            name: users
            schema: public
```

**All tables in a specific schema (PostgreSQL 15+):**
```yaml
publications:
  - name: schema-only
    dbname: app
    target:
      objects:
        - tablesInSchema: my_schema
```

Subscriber Cluster Configuration
--------------------------------

The subscriber cluster creates a subscription that receives data from a publication.

```yaml
type: postgresql
mode: standalone

cluster:
  instances: 1
  enableSuperuserAccess: true

subscriptions:
  - name: from_publisher
    dbname: app
    publicationName: all-tables
    externalClusterName: publisher
    subscriptionReclaimPolicy: delete

logicalReplication:
  externalClusters:
    - name: publisher
      host: publisher-cluster-rw.default.svc
      port: 5432
      username: postgres
      database: app
      sslMode: require
      passwordSecret:
        create: false
        name: publisher-cluster-superuser
        key: password
```

Important Notes
---------------

### Subscription Naming

Subscription names must use underscores (`from_publisher`), not hyphens (`from-publisher`), due to PostgreSQL replication slot naming constraints.

### Schema Synchronization

DDL (table structure changes) is not replicated. You must ensure:
1. Tables exist on the subscriber before the subscription activates
2. Schema changes are applied to both clusters manually

### External Cluster Connection

The `logicalReplication.externalClusters` section defines how to connect to the publisher:
- `host`: The publisher's service name (e.g., `publisher-cluster-rw.namespace.svc`)
- `username`: A user with REPLICATION privilege (the `postgres` superuser has this by default)
- `passwordSecret`: Reference to a secret containing the password

### Password Secret

You can either:
- Reference an existing secret (`create: false`)
- Have the chart create one (`create: true` with `value` specified)

Example configurations can be found in the [examples](../examples) directory:
- `logical-replication-publisher.yaml`
- `logical-replication-subscriber.yaml`

For advanced configuration options, see the [CloudNativePG documentation](https://cloudnative-pg.io/docs/devel/logical_replication/).
