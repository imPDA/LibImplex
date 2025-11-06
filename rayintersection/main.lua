local abs = math.abs
local sqrt = math.sqrt

-- ----------------------------------------------------------------------------

local measurements = {}

local MARKERS_CONTROL_2D = LibImplex_2DMarkers
local MARKERS_CONTROL_2D_NAME = 'LibImplex_2DMarkers'

-- ----------------------------------------------------------------------------

-- Gaussian elimination for 3x3 system
local function solve3x3(A, b)
    -- Make a copy of the matrices
    local M = {
        {A[1][1], A[1][2], A[1][3], b[1]},
        {A[2][1], A[2][2], A[2][3], b[2]},
        {A[3][1], A[3][2], A[3][3], b[3]}
    }

    -- Forward elimination
    for i = 1, 3 do
        -- Find pivot
        local maxRow = i
        for j = i + 1, 3 do
            if abs(M[j][i]) > abs(M[maxRow][i]) then
                maxRow = j
            end
        end

        -- Swap rows
        M[i], M[maxRow] = M[maxRow], M[i]

        -- Check for singular matrix
        if abs(M[i][i]) < 1e-10 then
            return nil
        end

        -- Eliminate
        for j = i + 1, 3 do
            local factor = M[j][i] / M[i][i]
            for k = i, 4 do
                M[j][k] = M[j][k] - factor * M[i][k]
            end
        end
    end

    -- Back substitution
    local x = {0, 0, 0}
    for i = 3, 1, -1 do
        x[i] = M[i][4]
        for j = i + 1, 3 do
            x[i] = x[i] - M[i][j] * x[j]
        end
        x[i] = x[i] / M[i][i]
    end

    return x
end

-- ----------------------------------------------------------------------------

local function addMeasurement()
    Set3DRenderSpaceToCurrentCamera(MARKERS_CONTROL_2D_NAME)

    local cX, cY, cZ = GuiRender3DPositionToWorldPosition(MARKERS_CONTROL_2D:Get3DRenderSpaceOrigin())
    local fX, fY, fZ = MARKERS_CONTROL_2D:Get3DRenderSpaceForward()

    table.insert(measurements, {
        position = {x = cX, y = cY, z = cZ},
        direction = {x = fX, y = fY, z = fZ}
    })

    -- d(string.format('Added measurement %d', #measurements))
end

local function vectorSubtract(a, b)
    return {x = a.x - b.x, y = a.y - b.y, z = a.z - b.z}
end

local function vectorScale(v, s)
    return {x = v.x * s, y = v.y * s, z = v.z * s}
end

local function vectorDot(a, b)
    return a.x * b.x + a.y * b.y + a.z * b.z
end

local function vectorLength(v)
    return sqrt(v.x * v.x + v.y * v.y + v.z * v.z)
end

local function vectorNormalize(v)
    local len = vectorLength(v)
    if len > 0 then
        return {x = v.x / len, y = v.y / len, z = v.z / len}
    else
        return {x = 0, y = 0, z = 0}
    end
end

local function findClosestIntersection()
    if #measurements < 2 then
        d('Need at least 2 measurements')
        return nil
    end

    local A = {}
    local b = {}

    for i = 1, #measurements do
        local m = measurements[i]
        local p = m.position
        local d = m.direction

        -- Normalize direction vector
        local d_norm = vectorNormalize(d)

        -- For each ray, we add the equation: (I - d*d^T)P = (I - d*d^T)C
        -- Where I is identity, d is direction, P is our point, C is camera position

        local I_minus_ddT = {
            {1 - d_norm.x * d_norm.x, -d_norm.x * d_norm.y, -d_norm.x * d_norm.z},
            {-d_norm.y * d_norm.x, 1 - d_norm.y * d_norm.y, -d_norm.y * d_norm.z},
            {-d_norm.z * d_norm.x, -d_norm.z * d_norm.y, 1 - d_norm.z * d_norm.z}
        }

        local right_side = {
            I_minus_ddT[1][1] * p.x + I_minus_ddT[1][2] * p.y + I_minus_ddT[1][3] * p.z,
            I_minus_ddT[2][1] * p.x + I_minus_ddT[2][2] * p.y + I_minus_ddT[2][3] * p.z,
            I_minus_ddT[3][1] * p.x + I_minus_ddT[3][2] * p.y + I_minus_ddT[3][3] * p.z
        }

        -- Add to our linear system
        for row = 1, 3 do
            if not A[(i-1)*3 + row] then
                A[(i-1)*3 + row] = {}
                b[(i-1)*3 + row] = 0
            end

            A[(i-1)*3 + row][1] = I_minus_ddT[row][1]
            A[(i-1)*3 + row][2] = I_minus_ddT[row][2]
            A[(i-1)*3 + row][3] = I_minus_ddT[row][3]
            b[(i-1)*3 + row] = right_side[row]
        end
    end

    -- Solve using least squares: A^T * A * X = A^T * b
    local ATA = {
        {0, 0, 0},
        {0, 0, 0},
        {0, 0, 0}
    }
    local ATb = {0, 0, 0}

    -- Calculate A^T * A and A^T * b
    for i = 1, #b do
        for j = 1, 3 do
            for k = 1, 3 do
                ATA[j][k] = ATA[j][k] + A[i][j] * A[i][k]
            end
            ATb[j] = ATb[j] + A[i][j] * b[i]
        end
    end

    -- Solve the 3x3 system using Gaussian elimination
    local result = solve3x3(ATA, ATb)

    if result then
        -- df('Closest intersection point: (%.3f, %.3f, %.3f)', result[1], result[2], result[3])
        return result[1], result[2], result[3]
    else
        -- d('Could not find solution')
        return nil
    end
end

local function calculateAverageDistance(x, y, z)
    local totalDistance = 0

    for _, m in ipairs(measurements) do
        local p = m.position
        local d = vectorNormalize(m.direction)

        -- Vector from camera to point
        local cameraToPoint = vectorSubtract({x=x, y=y, z=z}, p)

        -- Projection of cameraToPoint onto ray direction
        local projection = vectorScale(d, vectorDot(cameraToPoint, d))

        -- Perpendicular component (shortest distance from point to ray)
        local perpendicular = vectorSubtract(cameraToPoint, projection)
        local distance = vectorLength(perpendicular)

        totalDistance = totalDistance + distance
    end

    return totalDistance / #measurements
end

local function getPointsAroundProjection(rayPoint, direction, point)
    local m = sqrt(direction.x * direction.x + direction.y * direction.y + direction.z * direction.z)

    local nD = {x = direction.x / m, y = direction.y / m, z = direction.z / m}

    local P = {
        x = point.x - rayPoint.x,
        y = point.y - rayPoint.y,
        z = point.z - rayPoint.z
    }

    local projectionLength = P.x * nD.x + P.y * nD.y + P.z * nD.z

    local projectedPoint = {
        x = rayPoint.x + nD.x * projectionLength,
        y = rayPoint.y + nD.y * projectionLength,
        z = rayPoint.z + nD.z * projectionLength
    }

    local pointBefore = {
        projectedPoint.x - nD.x * 10 * 100,
        projectedPoint.y - nD.y * 10 * 100,
        projectedPoint.z - nD.z * 10 * 100
    }

    local pointAfter = {
        projectedPoint.x + nD.x * 10 * 100,
        projectedPoint.y + nD.y * 10 * 100,
        projectedPoint.z + nD.z * 10 * 100
    }

    return pointBefore, pointAfter
end

local INTERSECTION
local LINES = {}

local function measure()
    addMeasurement()

    LibImplex_RayIntersection:GetNamedChild('Text'):SetText(('Measurements: %d'):format(#measurements))
    if #measurements < 2 then return end

    local iX, iY, iZ = findClosestIntersection()
    if not iX then return end

    local avgDist = calculateAverageDistance(iX, iY, iZ)
    LibImplex_RayIntersection:GetNamedChild('Text'):SetText(
        ('Total measurements: %d\nx: %.2f, y: %.2f, z: %.2f\nAverage distance to rays: %.2f cm'):format(#measurements, iX, iY, iZ, avgDist)
    )

    if INTERSECTION then INTERSECTION:Delete() end
    INTERSECTION = LibImplex.Marker.Marker2D(
        {iX, iY, iZ},
        nil,
        '/esoui/art/miscellaneous/gamepad/gp_bullet.dds',
        {24, 24},
        {1, 1, 0}
    )

    for i = 1, #LINES do
        local line = LINES[i]
        line:Delete()
    end
    ZO_ClearNumericallyIndexedTable(LINES)

    for i = 1, #measurements do
        local measurement = measurements[i]
        local before, after = getPointsAroundProjection(measurement.position, measurement.direction, {x=iX, y=iY, z=iZ})
        LINES[#LINES+1] = LibImplex.Lines.Line(before, after)
    end
end

local function clearMeasurements()
    if INTERSECTION then
        INTERSECTION:Delete()
        INTERSECTION = nil
    end

    for i = 1, #LINES do
        local line = LINES[i]
        line:Delete()
    end
    ZO_ClearNumericallyIndexedTable(LINES)

    ZO_ClearNumericallyIndexedTable(measurements)

    LibImplex_RayIntersection:GetNamedChild('Text'):SetText('Cleaned')
end

do
    LibImplex_RayIntersection:GetNamedChild('Measure'):SetHandler("OnClicked", measure)
    LibImplex_RayIntersection:GetNamedChild('Clear'):SetHandler("OnClicked", clearMeasurements)
end
