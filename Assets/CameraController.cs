using UnityEngine;
using System.Collections;

public class CameraController : MonoBehaviour
{
    public Transform target;
    public Vector3 targetOffset;
    public float distance = 5.0f;
    public float maxDistance = 20;
    public float minDistance = .6f;
    public float xSpeed = 200.0f;
    public float ySpeed = 200.0f;
    public int yMinLimit = -80;
    public int yMaxLimit = 80;
    public int zoomRate = 40;
    public float panSpeed = 0.3f;
    public float zoomDampening = 5.0f;

    private float xDeg = 0.0f;
    private float yDeg = 0.0f;
    private float currentDistance;
    private float desiredDistance;
    private Quaternion currentRotation;
    private Quaternion desiredRotation;
    private Quaternion rotation;
    private Vector3 position;

    void Start() { Init(); }
    void OnEnable() { Init(); }

    public void Init()
    {
        distance = Vector3.Distance(transform.position, target.position);
        currentDistance = distance;
        desiredDistance = distance;
        
        position = transform.position;
        rotation = transform.rotation;
        currentRotation = transform.rotation;
        desiredRotation = transform.rotation;

        xDeg = Vector3.Angle(Vector3.right, transform.right);
        yDeg = Vector3.Angle(Vector3.up, transform.up);
    }

    void DoOrbit()
    {
        xDeg += Input.GetAxis("Mouse X") * xSpeed * 0.02f;
        yDeg -= Input.GetAxis("Mouse Y") * ySpeed * 0.02f;
        
        yDeg = ClampAngle(yDeg, yMinLimit, yMaxLimit);
        desiredRotation = Quaternion.Euler(yDeg, xDeg, 0);
        currentRotation = transform.rotation;

        rotation = Quaternion.Lerp(currentRotation, desiredRotation, Time.deltaTime * zoomDampening);
        transform.rotation = rotation;
    }

    void DoPan()
    {
        target.rotation = transform.rotation;
        target.Translate(Vector3.right * -Input.GetAxis("Mouse X") * panSpeed);
        target.Translate(transform.up * -Input.GetAxis("Mouse Y") * panSpeed, Space.World);
    }

    void DoZoom()
    {
        desiredDistance -= Input.GetAxis("Mouse Y") * Time.deltaTime * zoomRate * 0.125f * Mathf.Abs(desiredDistance);
    }
    
    void LateUpdate()
    {
        bool shouldOrbit = Input.GetMouseButton(0);
        bool shouldPan = Input.GetMouseButton(2);
        bool shouldZoom = Input.GetMouseButton(1);
        if (shouldOrbit)
        {
            DoOrbit();
        }
        if(shouldPan)
        {
            DoPan();
        }
        if(shouldZoom)
        {
            DoZoom();
        }
        
        desiredDistance -= Input.GetAxis("Mouse ScrollWheel") * Time.deltaTime * zoomRate * Mathf.Abs(desiredDistance);
        desiredDistance = Mathf.Clamp(desiredDistance, minDistance, maxDistance);
        currentDistance = Mathf.Lerp(currentDistance, desiredDistance, Time.deltaTime * zoomDampening);
        position = target.position - (rotation * Vector3.forward * currentDistance + targetOffset);
        transform.position = position;
    }

    private static float ClampAngle(float angle, float min, float max)
    {
        if (angle < -360)
            angle += 360;
        if (angle > 360)
            angle -= 360;
        return Mathf.Clamp(angle, min, max);
    }
}