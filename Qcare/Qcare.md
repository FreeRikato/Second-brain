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

{
    "ticket": [
        {
            "id": "1",
            "raised_on": "2026-01-05T08:10:23.211Z",
            "description": "sadf",
            "attachment": "asdf",
            "category_id": "1",
            "category_name": "Electrical",
            "location_id": "1",
            "location_name": "Room - Bedroom",
            "resident_id": "1",
            "resident_name": "Seed Test Building",
            "comment": "sadf",
            "status": "closed",
            "maintenance_id": "1",
            "modified_by": "Superadmin"
        },
        {
            "id": "1",
            "raised_on": "2026-01-05T08:10:23.211Z",
            "description": "sadf",
            "attachment": "asdf",
            "category_id": "1",
            "category_name": "Electrical",
            "location_id": "1",
            "location_name": "Room - Bedroom",
            "resident_id": "1",
            "resident_name": "Seed Test Building",
            "comment": "sadf",
            "status": "reopened",
            "maintenance_id": "1",
            "modified_by": "Superadmin"
        },
        {
            "id": "1",
            "raised_on": "2026-01-05T08:10:23.211Z",
            "description": "sadf",
            "attachment": "asdf",
            "category_id": "1",
            "category_name": "Electrical",
            "location_id": "1",
            "location_name": "Room - Bedroom",
            "resident_id": "1",
            "resident_name": "Seed Test Building",
            "comment": "sadf",
            "status": "closed",
            "maintenance_id": "1",
            "modified_by": "Superadmin"
        },
        {
            "id": "1",
            "raised_on": "2026-01-05T08:10:23.211Z",
            "description": "sadf",
            "attachment": "asdf",
            "category_id": "1",
            "category_name": "Electrical",
            "location_id": "1",
            "location_name": "Room - Bedroom",
            "resident_id": "1",
            "resident_name": "Seed Test Building",
            "comment": "sadf",
            "status": "active",
            "maintenance_id": "1",
            "modified_by": "Superadmin"
        }
    ]
} ^SC0ahbPl

INSERT INTO public.maintenance_tickets
(id, created_at, updated_at, deleted_at, description, attachment, raised_by, building_id, category_id, raised_by_type, location_id)
VALUES(1, '2026-01-05 13:40:23.211', '2026-01-05 13:40:23.211', NULL, 'sadf', 'asdf', 1, 1, 1, 'internal_user'::public."maintenance_tickets_raised_by_type_enum", 1);
INSERT INTO public.maintenance_tickets
(id, created_at, updated_at, deleted_at, description, attachment, raised_by, building_id, category_id, raised_by_type, location_id)
VALUES(2, '2026-01-05 13:40:23.211', '2026-01-05 13:40:23.211', NULL, 'sadf', 'asdf', 2, 1, 2, 'internal_user'::public."maintenance_tickets_raised_by_type_enum", 2);
INSERT INTO public.maintenance_tickets
(id, created_at, updated_at, deleted_at, description, attachment, raised_by, building_id, category_id, raised_by_type, location_id)
VALUES(3, '2026-01-05 13:40:23.211', '2026-01-05 13:40:23.211', NULL, 'sadf', 'asdf', 3, 1, 3, 'user_profile'::public."maintenance_tickets_raised_by_type_enum", 3);
INSERT INTO public.maintenance_tickets
(id, created_at, updated_at, deleted_at, description, attachment, raised_by, building_id, category_id, raised_by_type, location_id)
VALUES(4, '2026-01-05 14:44:13.467', '2026-01-05 14:44:13.467', NULL, 'sdf', 'asdf', 1, 1, 1, 'user_profile'::public."maintenance_tickets_raised_by_type_enum", 1); ^5eGZZMbU

INSERT INTO public.maintenance_ticket_tracking
(id, created_at, updated_at, deleted_at, "comment", status, modified_by, modified_by_type, assignee_id, maintenance_id)
VALUES(1, '2026-01-05 13:40:42.007', '2026-01-05 13:40:42.007', NULL, 'sadf', 'active'::public."maintenance_ticket_tracking_status_enum", 1, 'internal_user'::public."maintenance_ticket_tracking_modified_by_type_enum", 1, 1);
INSERT INTO public.maintenance_ticket_tracking
(id, created_at, updated_at, deleted_at, "comment", status, modified_by, modified_by_type, assignee_id, maintenance_id)
VALUES(2, '2026-01-05 14:00:07.202', '2026-01-05 14:00:07.202', NULL, 'sadf', 'closed'::public."maintenance_ticket_tracking_status_enum", 1, 'internal_user'::public."maintenance_ticket_tracking_modified_by_type_enum", 1, 1);
INSERT INTO public.maintenance_ticket_tracking
(id, created_at, updated_at, deleted_at, "comment", status, modified_by, modified_by_type, assignee_id, maintenance_id)
VALUES(3, '2026-01-05 14:30:33.774', '2026-01-05 14:30:33.774', NULL, 'sadf', 'reopened'::public."maintenance_ticket_tracking_status_enum", 1, 'internal_user'::public."maintenance_ticket_tracking_modified_by_type_enum", 1, 1);
INSERT INTO public.maintenance_ticket_tracking
(id, created_at, updated_at, deleted_at, "comment", status, modified_by, modified_by_type, assignee_id, maintenance_id)
VALUES(4, '2026-01-05 15:00:33.774', '2026-01-05 15:00:33.774', NULL, 'sadf', 'closed'::public."maintenance_ticket_tracking_status_enum", 1, 'internal_user'::public."maintenance_ticket_tracking_modified_by_type_enum", 1, 1);
INSERT INTO public.maintenance_ticket_tracking
(id, created_at, updated_at, deleted_at, "comment", status, modified_by, modified_by_type, assignee_id, maintenance_id)
VALUES(5, '2026-01-05 15:00:33.774', '2026-01-05 15:00:33.774', NULL, 'sadf', 'active'::public."maintenance_ticket_tracking_status_enum", 2, 'internal_user'::public."maintenance_ticket_tracking_modified_by_type_enum", 2, 2);
INSERT INTO public.maintenance_ticket_tracking
(id, created_at, updated_at, deleted_at, "comment", status, modified_by, modified_by_type, assignee_id, maintenance_id)
VALUES(6, '2026-01-05 15:00:33.774', '2026-01-05 15:00:33.774', NULL, 'sadf', 'active'::public."maintenance_ticket_tracking_status_enum", 3, 'user_profile'::public."maintenance_ticket_tracking_modified_by_type_enum", 3, 3);
INSERT INTO public.maintenance_ticket_tracking
(id, created_at, updated_at, deleted_at, "comment", status, modified_by, modified_by_type, assignee_id, maintenance_id)
VALUES(7, '2026-01-05 15:00:33.774', '2026-01-05 15:00:33.774', NULL, 'sadf', 'active'::public."maintenance_ticket_tracking_status_enum", 1, 'user_profile'::public."maintenance_ticket_tracking_modified_by_type_enum", 1, 4);
INSERT INTO public.maintenance_ticket_tracking
(id, created_at, updated_at, deleted_at, "comment", status, modified_by, modified_by_type, assignee_id, maintenance_id)
VALUES(9, '2026-01-06 18:35:00.174', '2026-01-06 18:35:00.174', NULL, 'sadf', 'closed'::public."maintenance_ticket_tracking_status_enum", 3, 'user_profile'::public."maintenance_ticket_tracking_modified_by_type_enum", 3, 3);
INSERT INTO public.maintenance_ticket_tracking
(id, created_at, updated_at, deleted_at, "comment", status, modified_by, modified_by_type, assignee_id, maintenance_id)
VALUES(8, '2026-01-06 18:35:04.167', '2026-01-06 17:58:42.653', NULL, 'sadf', 'closed'::public."maintenance_ticket_tracking_status_enum", 1, 'user_profile'::public."maintenance_ticket_tracking_modified_by_type_enum", 1, 4);
INSERT INTO public.maintenance_ticket_tracking
(id, created_at, updated_at, deleted_at, "comment", status, modified_by, modified_by_type, assignee_id, maintenance_id)
VALUES(10, '2026-01-06 18:55:00.174', '2026-01-06 18:35:00.174', NULL, 'sadf', 'reopened'::public."maintenance_ticket_tracking_status_enum", 3, 'user_profile'::public."maintenance_ticket_tracking_modified_by_type_enum", 3, 3);
INSERT INTO public.maintenance_ticket_tracking
(id, created_at, updated_at, deleted_at, "comment", status, modified_by, modified_by_type, assignee_id, maintenance_id)
VALUES(29, '2026-01-07 00:53:19.856', '2026-01-07 00:53:19.856', NULL, 'This is testing description for the maintenance ticket creation to resident', 'closed'::public."maintenance_ticket_tracking_status_enum", 1, 'internal_user'::public."maintenance_ticket_tracking_modified_by_type_enum", 2, 2);
INSERT INTO public.maintenance_ticket_tracking
(id, created_at, updated_at, deleted_at, "comment", status, modified_by, modified_by_type, assignee_id, maintenance_id)
VALUES(30, '2026-01-07 00:53:38.267', '2026-01-07 00:53:38.267', NULL, 'This is testing description for the maintenance ticket creation to resident', 'reopened'::public."maintenance_ticket_tracking_status_enum", 1, 'internal_user'::public."maintenance_ticket_tracking_modified_by_type_enum", 2, 2);
INSERT INTO public.maintenance_ticket_tracking
(id, created_at, updated_at, deleted_at, "comment", status, modified_by, modified_by_type, assignee_id, maintenance_id)
VALUES(31, '2026-01-07 00:53:54.980', '2026-01-07 00:53:54.980', NULL, 'This is testing description for the maintenance ticket creation to resident', 'escalated'::public."maintenance_ticket_tracking_status_enum", 1, 'internal_user'::public."maintenance_ticket_tracking_modified_by_type_enum", 2, 2);
INSERT INTO public.maintenance_ticket_tracking
(id, created_at, updated_at, deleted_at, "comment", status, modified_by, modified_by_type, assignee_id, maintenance_id)
VALUES(32, '2026-01-07 00:54:09.897', '2026-01-07 00:54:09.897', NULL, 'This is testing description for the maintenance ticket creation to resident', 'closed'::public."maintenance_ticket_tracking_status_enum", 1, 'internal_user'::public."maintenance_ticket_tracking_modified_by_type_enum", 2, 2); ^93Rm9J36

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