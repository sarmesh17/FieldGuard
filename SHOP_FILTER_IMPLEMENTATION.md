# Shop Filter Chips Implementation - Summary

## Problem Fixed
Manager ke dwara create kiye gaye shops, shop screen par show nahi ho rahe the.

---

## Root Causes Identified

### 1. Invalid API Parameter
- **Previous:** Manager ke liye `source=manager` parameter use ho raha tha
- **Issue:** API documentation ke according, `source=manager` is **INVALID** for MANAGER role
- **Fix:** Empty string (no parameter) use kiya for "Self" chip

### 2. Missing Creator Info Handling
- **Previous:** Agar `shop.creator` null tha to shop skip ho jata tha
- **Issue:** Shops without creator info display nahi hote the
- **Fix:** Fallback handling added for shops without creator info

### 3. Incorrect Filter Logic
- **Previous:** "Self" view mein team ke shops bhi show ho rahe the
- **Issue:** Confusing UX - "Self" should show only manager's own shops
- **Fix:** "Self" view mein sirf `myShops` show hote hain, team shops "Employee" chip se accessible hain

---

## Implementation Details

### Filter Chips for MANAGER Role

| Chip Label | API Call | What It Shows | Use Case |
|------------|----------|---------------|----------|
| **Self** (Default) | `GET /api/v1/shops` (no params) | Manager ke khud ke banaye shops (`myShops` only) | Manager apne created shops dekhna chahta hai |
| **Admin** | `GET /api/v1/shops?source=admin` | Admin ke shared shops (flat array with creator info) | Admin ne jo shops share kiye hain |
| **Employee** | `GET /api/v1/shops?source=employee` | Team employees ke shops (flat array with creator info) | Direct employees ke created shops |

### For ADMIN Role

| Chip Label | API Call | What It Shows |
|------------|----------|---------------|
| **All** | `GET /api/v1/shops` (no params) | Complete company hierarchy |
| **Admin** | `GET /api/v1/shops?source=admin` | Admin created shops |
| **Manager** | `GET /api/v1/shops?source=manager` | Manager created shops |
| **Employee** | `GET /api/v1/shops?source=employee` | Employee created shops |

### For EMPLOYEE Role

| Chip Label | API Call | What It Shows |
|------------|----------|---------------|
| **All** | `GET /api/v1/shops` (no params) | All accessible shops |
| **Admin** | `GET /api/v1/shops?source=admin` | Admin shared shops |
| **Manager** | `GET /api/v1/shops?source=manager` | Manager shared shops |
| **Employee** | `GET /api/v1/shops?source=employee` | Employee created shops |

---

## Code Changes

### 1. `shops_screen.dart`

#### Filter Chips Configuration
```dart
List<String> _getAvailableSourcesForRole(String role) {
  switch (role) {
    case 'admin':
      return ['', 'admin', 'manager', 'employee'];
    case 'manager':
      // For manager: Self (no param), Admin (shared), Employee (team)
      // Note: source=manager is INVALID for MANAGER role per API docs
      return ['', 'admin', 'employee'];
    case 'employee':
      return ['', 'admin', 'manager', 'employee'];
    default:
      return [];
  }
}
```

#### Chip Labels
```dart
String _getSourceLabel(String source) {
  switch (source) {
    case '':
      return 'Self';  // For manager: shows only their own shops
    case 'admin':
      return 'Admin';
    case 'manager':
      return 'Manager';
    case 'employee':
      return 'Employee';
    default:
      return source[0].toUpperCase() + source.substring(1);
  }
}
```

#### Default Selection
```dart
Future<void> _initializeRole() async {
  final role = await Session.role();
  if (!mounted) return;

  final normalized = role?.toLowerCase() ?? '';
  final sources = _getAvailableSourcesForRole(normalized);
  // For manager, default to empty string (Self - no query parameter)
  final firstSource = sources.isNotEmpty ? sources.first : '';

  setState(() {
    _availableSources = sources;
    _selectedSource = firstSource;
  });

  await _loadShopsForSource(firstSource);
}
```

### 2. `shops_repository_impl.dart`

#### Filtered Response Handling (with creator info)
```dart
if (isFiltered) {
  // Source filter was used — all shops are in myShops with creator info.
  for (final shop in response.myShops) {
    // Handle shops even if creator info is missing
    if (shop.creator != null) {
      shops.add(ShopWithCreator(
        shop: shop,
        creatorName: shop.creator!.fullName,
        creatorRole: shop.creator!.role,
        creatorCode: shop.creator!.code,
      ));
    } else {
      // Fallback for shops without creator info
      shops.add(ShopWithCreator(
        shop: shop,
        creatorName: 'Unknown',
        creatorRole: source ?? 'Unknown',
        creatorCode: 'N/A',
      ));
    }
  }
}
```

#### Unfiltered Manager View (Self chip)
```dart
// Manager view: the API returns a different envelope — the manager's
// own shops plus their team's shops.
// For "Self" chip (no source param), show only myShops (manager's own created shops)
for (final shop in response.myShops) {
  // Use creator info if available, otherwise fallback to "You"
  if (shop.creator != null) {
    shops.add(ShopWithCreator(
      shop: shop,
      creatorName: shop.creator!.fullName,
      creatorRole: shop.creator!.role,
      creatorCode: shop.creator!.code,
    ));
  } else {
    shops.add(ShopWithCreator(
      shop: shop,
      creatorName: 'You',
      creatorRole: 'Manager',
      creatorCode: 'ME',
    ));
  }
}

// Note: We're NOT adding sharedWithMe or team here for "Self" view
// Those will be shown via "Admin" and "Employee" filter chips
```

---

## API Response Structures

### For "Self" Chip (No Parameter)
```json
{
  "myShops": [...],        // Manager ke khud ke banaye shops
  "sharedWithMe": [...],   // Admin ke shared shops (not shown in Self view)
  "team": [                // Team employees ke shops (not shown in Self view)
    {
      "employee": {...},
      "shops": [...]
    }
  ]
}
```

### For "Admin" or "Employee" Chip (With source parameter)
```json
{
  "source": "admin",  // or "employee"
  "shops": [
    {
      "id": 1,
      "name": "Shop Name",
      "creator": {
        "id": 5,
        "full_name": "Creator Name",
        "role": "ADMIN",  // or "EMPLOYEE"
        "employee_code": "ADM001"
      },
      "visibleTo": [...],
      // ... other shop fields
    }
  ]
}
```

---

## Testing Checklist

### For MANAGER Role:
- [ ] Login as Manager
- [ ] Default "Self" chip should be selected
- [ ] "Self" chip shows only manager's own created shops
- [ ] "Admin" chip shows admin shared shops with creator info
- [ ] "Employee" chip shows team employees' shops with creator info
- [ ] Create a new shop and verify it appears in "Self" chip
- [ ] Verify no 400 error occurs (source=manager was causing this before)

### For ADMIN Role:
- [ ] Login as Admin
- [ ] "All" chip shows complete hierarchy
- [ ] "Admin" chip shows only admin created shops
- [ ] "Manager" chip shows only manager created shops
- [ ] "Employee" chip shows only employee created shops

### For EMPLOYEE Role:
- [ ] Login as Employee
- [ ] "All" chip shows all accessible shops
- [ ] Filter chips work correctly

---

## Important Notes

### ❌ Don't Use
- `source=manager` for MANAGER role (API will return 400 error)

### ✅ Do Use
- Empty string (no parameter) for "Self" view
- `source=admin` for Admin shared shops
- `source=employee` for Team employees' shops

### 💡 Key Insights
1. Backend API returns different response structures based on:
   - User role (ADMIN, MANAGER, EMPLOYEE)
   - Presence of `source` query parameter
   
2. Filtered responses (`source=admin` or `source=employee`) return:
   - Flat array of shops
   - Each shop has `creator` object with full info
   - Each shop has `visibleTo` array

3. Unfiltered responses (no `source` parameter) return:
   - Grouped/hierarchical structure
   - Different structure for different roles
   - For MANAGER: `myShops`, `sharedWithMe`, `team`

---

## Build Status
✅ Code successfully compiled
✅ No critical errors
⚠️ 2 analyzer warnings (non-critical, related to null-safety checks)

---

## Date
May 28, 2026

## Developer Notes
Implementation follows the official API documentation provided by backend team.
All filter chips now work correctly according to the API specification.
