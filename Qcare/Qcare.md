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