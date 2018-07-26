using System;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;

public class Martingale : MonoBehaviour
{
    public int BetBase = 10;
    public int StartingCash = 1000;
    [Range(0, 499)]
    public int OddsOutOfAThousand = 499;
    [Range(0, 1)]
    public float SortStrength;

    private float OddsOfWinning { get { return (float)OddsOutOfAThousand / 1000; } }
    public int Sessions = 1000;

    public Material DataMat;
    private const int BufferStride =
        sizeof(float) // height
        + sizeof(float) // time
        + sizeof(float) // unsortedIndex
        + sizeof(float) // sortedIndex
        + sizeof(float) // sessionHeight
        + sizeof(float) // sessionValue
        + sizeof(float); // end
    private ComputeBuffer _theBuffer;
    private int bufferSize;

    private int _lastBetBase;
    private int _lastStartingCash;
    private int _lastOdds;

    private struct DataPoint
    {
        public float height;
        public float time;
        public float unsortedIndex;
        public float sortedIndex;
        public float sessionHeight;
        public float sessionValue;
        public float end;
    }

    private void Start()
    {
        UpdateData();
    }

    private void Update()
    {
        bool needsRefresh = GetNeedsRefresh();
        if (needsRefresh)
        {
            UpdateData();
        }
    }

    private bool GetNeedsRefresh()
    {
        bool ret = _lastBetBase != BetBase
            || _lastStartingCash != StartingCash
            || _lastOdds != OddsOutOfAThousand;
        _lastBetBase = BetBase;
        _lastStartingCash = StartingCash;
        _lastOdds = OddsOutOfAThousand;
        return ret;
    }

    private void UpdateData()
    {
        Session[] sourceData = GetSourceData();
        sourceData = SortData(sourceData);
        bufferSize = sourceData.Sum(item => item.CashHistory.Count);
        DataPoint[] data = GetDataForBuffer(bufferSize, sourceData);

        if(_theBuffer != null)
        {
            _theBuffer.Dispose();
        }
        _theBuffer = new ComputeBuffer(bufferSize, BufferStride);
        _theBuffer.SetData(data);
    }

    private Session[] SortData(Session[] sourceData)
    {
        return sourceData.OrderBy(item => item.CashHistory.Count).ToArray();
    }

    private DataPoint[] GetDataForBuffer(int bufferSize, Session[] sourceData)
    {
        float maxVal = sourceData.Max(item => item.CashHistory.Max());
        int maxDuration = sourceData.Max(item => item.CashHistory.Count);

        DataPoint[] ret = new DataPoint[bufferSize];
        int xIndex = 0;
        int totalCount = 0;
        foreach (Session session in sourceData)
        {
            int yIndex = 0;
            foreach (float point in session.CashHistory)
            {
                DataPoint dataPoint = MakePoint(session, point, xIndex, yIndex, Sessions, maxVal, maxDuration);
                ret[totalCount] = dataPoint;
                yIndex++;
                totalCount++;
            }
            ret[totalCount - 1].end = 1;
            xIndex++;
        }
        return ret;
    }

    private DataPoint MakePoint(Session session, float val, int xIndex, int yIndex, int sessionsCount, float maxVal, int maxDuration)
    {
        DataPoint ret = new DataPoint();
        ret.sessionHeight = session.CashHistory.Max() / maxVal;
        ret.sessionValue = (float)session.CashHistory.Count / maxDuration;
        ret.unsortedIndex = (float)session.Index / sessionsCount;
        ret.sortedIndex = (float)xIndex / sessionsCount;
        ret.height = val / maxVal;
        ret.time = (float)yIndex / maxDuration;
        return ret;
    }

    private Session[] GetSourceData()
    {
        Session[] ret = new Session[Sessions];
        for (int i = 0; i < Sessions; i++)
        {
            ret[i] = new Session(StartingCash, BetBase, OddsOfWinning, i);
        }
        return ret;
    }

    private void OnDestroy()
    {
        _theBuffer.Dispose();
    }

    private void OnRenderObject()
    {
        DataMat.SetBuffer("_TheBuffer", _theBuffer);
        DataMat.SetMatrix("_Transform", transform.localToWorldMatrix);
        DataMat.SetFloat("_SortStrength", SortStrength);
        DataMat.SetPass(0);
        Graphics.DrawProcedural(MeshTopology.Points, 1, bufferSize);
    }
}

public class Session
{
    private float CurrentCash;
    private float CurrentBet;
    private readonly float BetBase;
    private readonly float OddsOfWinning;
    private readonly List<float> _cashHistory;
    public int Index { get; }
    public List<float> CashHistory { get { return _cashHistory; } }

    public Session(float startingCash, float betBase, float oddsOfWinning, int index)
    {
        BetBase = betBase;
        OddsOfWinning = oddsOfWinning;
        CurrentCash = startingCash;
        Index = index;
        CurrentBet = BetBase;
        _cashHistory = new List<float>();
        while (CurrentCash > 0)
        {
            Gamble(CurrentBet);
            _cashHistory.Add(CurrentCash);
        }
    }

    private void Gamble(float betAmount)
    {
        if (betAmount > CurrentCash)
        {
            betAmount = CurrentCash;
        }
        bool win = UnityEngine.Random.value < OddsOfWinning;
        if (win)
        {
            CurrentCash += betAmount;
            CurrentBet = BetBase;
        }
        else
        {
            CurrentCash -= betAmount;
            CurrentBet *= 2;
        }
    }
}
