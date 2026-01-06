---

excalidraw-plugin: parsed
tags: [excalidraw]

---
==⚠  Switch to EXCALIDRAW VIEW in the MORE OPTIONS menu of this document. ⚠== You can decompress Drawing data with the command palette: 'Decompress current Excalidraw file'. For more info check in plugin settings under 'Saving'


# Excalidraw Data

## Text Elements
Issues found in the codebase ^6cV3FJ8p

Refresh token implementation

 ^P4iPjarP

QR Generation  ^b95v8JcR

Scenario 1 - No maintenance tickets ^T8xb95dK

No Maintenance tickets found ^eeRRy9OS

Scenario 2 - All buildings selected in All tab ^OMPcE4aG

ticket id, raised by, category, raised on, location, assignee, residence name, closed_on, status ^W8nrjs7v

Scenario 3 - Specific building selected in all tab ^iGzNDnCQ

ticket id, raised by, category, raised on, closed_on, location, assignee, status ^EL2qBRCJ

Scenario 4 - All buildings selected in closed/resolved tab ^oCXoyM7N

ticket id, raised by, category, raised on, location, assignee, residence name, closed_on, status ^a5Js3ua9

Scenario 5 - Specific building selected in closed/resolved tab ^1n9pJKLI

ticket id, raised by, category, raised on, location, assignee, closed_on, status ^t9y3ndX5

Issues with maintenance tracking ^pfRG5Ha1

modified_by ^djmQo3qA

raised_by ^dnqFQhFk

Both these values can come from both user_profile and internal_user ^iRCPZzh2

=> Its not possible to have foreign keys from different tables in one column ^WSbFYcnZ

Maintenance_tickets ^L8c6EpPq

Maintenance_ticket_tracking ^f4nGVYHg

There are different approaches to mitigate this issue - ^gmu1iv2a

1. Parent table to both user_profile and internal_users
2. Two nullable FKs for both columns - 
    raised_by_internal
    raised_by_resident
    modified_by_internal
    modified_by_resident
3. Separate enums called raised_by_type and modified_by_type
with values internal_user and user_profile ^l8FLnSBG

Maintenance_tickets ^rcbOcBSx

Maintenance_ticket_tracking ^lrwBhFrf

id
created_at
updated_at
deleted_at
comment
status
assignee
maintenance_id
modified_by
modified_by_type ^v4PDHUdG

active, escalated, closed, resolved, reopened ^RyxxqxYe

Internal_user ^fHhNqv4q

: varchar ^JNAkMsuU

: bigInt ^6jcrzLSf

internal_user, user_profile ^82Y59A2P

id
created_at
updated_at
deleted_at
building_id
category_id
description
attachment
location
raised_by
raised_by_type ^IxgfkB0G

Building ^HTxhsqKI

Meta_ticket_location ^N0paKyYn

Meta_ticket_issue ^hM30vrb2

: bigInt ^fDv9cxgG

internal_user, user_profile ^8yVhqLOd

: bigInt ^4Hrg84PT

: varchar ^S618w7Tt

: varchar ^LSfvGogs

MaintenanceTicketActor ^C2PzwSRF

MaintenanceTicketActor ^NajiFzBF

MaintenanceStatus ^W6S2O7cm

ticket Maintenance {
  id: '1',
  createdAt: 2026-01-05T08:10:23.211Z,
  updatedAt: 2026-01-05T08:10:23.211Z,
  deletedAt: null,
  description: 'sadf',
  attachment: 'asdf',
  raisedBy: '1',
  raisedByType: 'internal_user',
  tracking: [
    MaintenanceTicketTracking {
      id: '1',
      createdAt: 2026-01-05T08:10:42.007Z,
      updatedAt: 2026-01-05T08:10:42.007Z,
      deletedAt: null,
      comment: 'sadf',
      status: 'active',
      modifiedBy: '1',
      modifiedByType: 'internal_user'
    },
    MaintenanceTicketTracking {
      id: '2',
      createdAt: 2026-01-05T08:30:07.202Z,
      updatedAt: 2026-01-05T08:30:07.202Z,
      deletedAt: null,
      comment: 'sadf',
      status: 'closed',
      modifiedBy: '1',
      modifiedByType: 'internal_user'
    },
    MaintenanceTicketTracking {
      id: '3',
      createdAt: 2026-01-05T09:00:33.774Z,
      updatedAt: 2026-01-05T09:00:33.774Z,
      deletedAt: null,
      comment: 'sadf',
      status: 'reopened',
      modifiedBy: '1',
      modifiedByType: 'internal_user'
    },
    MaintenanceTicketTracking {
      id: '4',
      createdAt: 2026-01-05T09:30:33.774Z,
      updatedAt: 2026-01-05T09:30:33.774Z,
      deletedAt: null,
      comment: 'sadf',
      status: 'closed',
      modifiedBy: '1',
      modifiedByType: 'internal_user'
    },
    MaintenanceTicketTracking {
      id: '7',
      createdAt: 2026-01-05T09:30:33.774Z,
      updatedAt: 2026-01-05T09:30:33.774Z,
      deletedAt: null,
      comment: 'sadf',
      status: 'active',
      modifiedBy: '1',
      modifiedByType: 'user_profile'
    }
  ],
  category: MetaTicketIssue {
    id: '1',
    createdAt: 2026-01-05T07:21:37.038Z,
    updatedAt: 2026-01-05T07:21:37.038Z,
    deletedAt: null,
    name: 'Electrical'
  },
  location: MetaTicketLocation {
    id: '1',
    createdAt: 2026-01-05T07:21:37.038Z,
    updatedAt: 2026-01-05T07:21:37.038Z,
    deletedAt: null,
    name: 'Room - Bedroom'
  },
  building: Building {
    id: '1',
    createdAt: 2026-01-05T07:21:37.038Z,
    updatedAt: 2026-01-05T07:21:37.038Z,
    deletedAt: null,
    name: 'Seed Test Building',
    legalName: 'Seed Test Building Legal Name',
    shortCode: 'STB',
    pKey: 'seed-test-pkey',
    siteCode: 'STB-001',
    merchantId: 'MERCH-STB-001',
    bankGlCode: 'GL-STB-001',
    vizmoCode: 'VIZ-STB-001',
    imageKey: null
  }
} ^vv3YtwTg

Instead of findOneOrFail query builder should be used to mititage the N+1 query problem that occurs due to polymorphic association ^zmUO9zAH

category id
category name
location id
location name
resident id
resident name
raised on
description
attachment
 ^MuvXjhaF

{
    "ticket": {
        "id": "1",
        "category": {
            "id": "1",
            "name": "Electrical"
        },
        "location": {
            "id": "1",
            "name": "Room - Bedroom"
        },
        "resident": {
            "id": "1",
            "name": "Seed Test Building"
        },
        "raised_on": "2026-01-05T08:10:23.211Z",
        "description": "sadf",
        "attachment": "asdf",
        "closed_on": "2026-01-05T09:30:33.774Z",
        "ticket_history": [
            {
                "id": "2",
                "modified_on": "2026-01-05T08:30:07.202Z",
                "from_status": "active",
                "to_status": "closed",
                "modified_by": "Superadmin",
                "comment": "sadf"
            },
            {
                "id": "3",
                "modified_on": "2026-01-05T09:00:33.774Z",
                "from_status": "closed",
                "to_status": "reopened",
                "modified_by": "Superadmin",
                "comment": "sadf"
            },
            {
                "id": "4",
                "modified_on": "2026-01-05T09:30:33.774Z",
                "from_status": "reopened",
                "to_status": "closed",
                "modified_by": "Superadmin",
                "comment": "sadf"
            }
        ]
    }
} ^wG4mP4eq

[
  {
    id: '1',
    raised_on: 2026-01-05T08:10:23.211Z,
    description: 'sadf',
    attachment: 'asdf',
    category_id: '1',
    category_name: 'Electrical',
    location_id: '1',
    location_name: 'Room - Bedroom',
    resident_id: '1',
    resident_name: 'Seed Test Building',
    comment: 'sadf',
    status: 'closed',
    maintenance_id: '1',
    modified_by_name: 'Superadmin'
  },
  {
    id: '1',
    raised_on: 2026-01-05T08:10:23.211Z,
    description: 'sadf',
    attachment: 'asdf',
    category_id: '1',
    category_name: 'Electrical',
    location_id: '1',
    location_name: 'Room - Bedroom',
    resident_id: '1',
    resident_name: 'Seed Test Building',
    comment: 'sadf',
    status: 'reopened',
    maintenance_id: '1',
    modified_by_name: 'Superadmin'
  },
  {
    id: '1',
    raised_on: 2026-01-05T08:10:23.211Z,
    description: 'sadf',
    attachment: 'asdf',
    category_id: '1',
    category_name: 'Electrical',
    location_id: '1',
    location_name: 'Room - Bedroom',
    resident_id: '1',
    resident_name: 'Seed Test Building',
    comment: 'sadf',
    status: 'closed',
    maintenance_id: '1',
    modified_by_name: 'Superadmin'
  },
  {
    id: '1',
    raised_on: 2026-01-05T08:10:23.211Z,
    description: 'sadf',
    attachment: 'asdf',
    category_id: '1',
    category_name: 'Electrical',
    location_id: '1',
    location_name: 'Room - Bedroom',
    resident_id: '1',
    resident_name: 'Seed Test Building',
    comment: 'sadf',
    status: 'active',
    maintenance_id: '1',
    modified_by_name: 'Superadmin'
  },
  {
    id: '2',
    raised_on: 2026-01-05T08:10:23.211Z,
    description: 'sadf',
    attachment: 'asdf',
    category_id: '2',
    category_name: 'Plumbing',
    location_id: '2',
    location_name: 'Room - Bathroom',
    resident_id: '1',
    resident_name: 'Seed Test Building',
    comment: 'sadf',
    status: 'active',
    maintenance_id: '2',
    modified_by_name: 'Customercare'
  },
  {
    id: '3',
    raised_on: 2026-01-05T08:10:23.211Z,
    description: 'sadf',
    attachment: 'asdf',
    category_id: '3',
    category_name: 'Paint Works',
    location_id: '3',
    location_name: 'Room - Kitchen',
    resident_id: '1',
    resident_name: 'Seed Test Building',
    comment: 'sadf',
    status: 'active',
    maintenance_id: '3',
    modified_by_name: 'Maya Johnson'
  },
  {
    id: '4',
    raised_on: 2026-01-05T09:14:13.467Z,
    description: 'sdf',
    attachment: 'asdf',
    category_id: '1',
    category_name: 'Electrical',
    location_id: '1',
    location_name: 'Room - Bedroom',
    resident_id: '1',
    resident_name: 'Seed Test Building',
    comment: 'sadf',
    status: 'active',
    maintenance_id: '4',
    modified_by_name: 'Rohan Kumar'
  }
] ^ZyDl31hP

## Embedded Files
b0c8d07ff71ebe0587ac52515fcf51ebf6ddf0b0: [[Pasted Image 20251228011023_292.png]]

f4949aafa1bb3a56676698745767f3d2af33a109: [[Pasted Image 20251228011056_416.png]]

ac600946ebe86133dca15a3b4d83d665994ae0f6: [[Pasted Image 20251228011132_560.png]]

bb5ba1208db383abf1d43fe826d6462426678b0d: [[Pasted Image 20251228011201_450.png]]

a7501bb0fec79b84134e432f8798a4d12612fda4: [[Pasted Image 20251228014626_824.png]]

%%
## Drawing
```compressed-json
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
```
%%