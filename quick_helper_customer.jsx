import React, { useState, useMemo, useEffect } from 'react';
import { Hourglass, Wrench, Sparkles, Zap, Hand, LocateFixed, Users, BadgeCheck, MapPin, LoaderCircle, User, Star, XCircle, CheckCircle, Clock, Home, DollarSign, LogIn, UserCheck, AlertTriangle } from 'lucide-react';
// Firebase Imports
import { initializeApp } from 'firebase/app';
import { getAuth, signInAnonymously, signInWithCustomToken, onAuthStateChanged, signInWithEmailAndPassword, createUserWithEmailAndPassword } from 'firebase/auth';
import { getFirestore, onSnapshot, collection, query, limit, addDoc, doc, setDoc } from 'firebase/firestore';

// --- SERVICE API KEYS (Placeholders) ---
// Note: In Live APK, these placeholders MUST be replaced with actual keys.
const GOOGLE_MAPS_API_KEY = "YOUR_GOOGLE_MAPS_API_KEY_HERE"; // For Live Map Integration in React Native
const RAZORPAY_PUBLISHABLE_KEY = "rzp_test_YOUR_RAZORPAY_PUBLISHABLE_KEY_HERE"; // For Live Payments

// --- Global App Constants ---
const APP_NAME = "Quick Helper (Customer)";
const APP_TAGLINE = "Your On-Demand Service Booking App";
const AVG_HELPER_RATE_PER_HOUR = 145; 
const APP_COMMISSION_PER_HOUR = 20;    
const USER_LOCATION = { lat: 19.1834, lng: 72.8407 }; 

const tasks = [
  { name: 'General Assistant', icon: Hand },
  { name: 'Plumbing Service', icon: Wrench },
  { name: 'Deep Cleaning', icon: Sparkles },
  { name: 'Electrician', icon: Zap },
];

// --- Utility Functions ---
const calculateDistance = (lat1, lon1, lat2, lon2) => {
    const R = 6371;
    const dLat = (lat2 - lat1) * (Math.PI / 180);
    const dLon = (lon2 - lon1) * (Math.PI / 180);
    const a = 
        Math.sin(dLat / 2) * Math.sin(dLat / 2) +
        Math.cos(lat1 * (Math.PI / 180)) * Math.cos(lat2 * (Math.PI / 180)) * Math.sin(dLon / 2) * Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.atan2(Math.sqrt(1 - a)));
    return (R * c).toFixed(1);
}
const calculateCost = (hours) => {
    const helperEarnings = hours * AVG_HELPER_RATE_PER_HOUR;
    const appCommission = hours * APP_COMMISSION_PER_HOUR;
    const totalCost = helperEarnings + appCommission;
    return { helperEarnings, appCommission, totalCost };
};

// --- Authentication Modal ---
const AuthModal = ({ auth, onClose }) => {
    const [isLogin, setIsLogin] = useState(true);
    const [email, setEmail] = useState('');
    const [password, setPassword] = useState('');
    const [error, setError] = useState('');
    const [loading, setLoading] = useState(false);

    const title = isLogin ? "Customer Login" : "Customer Sign Up";
    const buttonText = isLogin ? "Log In" : "Create Account";

    const handleSubmit = async () => {
        setError('');
        setLoading(true);
        try {
            if (isLogin) {
                await signInWithEmailAndPassword(auth, email, password);
            } else {
                await createUserWithEmailAndPassword(auth, email, password);
            }
            onClose(); 
        } catch (e) {
            setError(e.message);
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="fixed inset-0 bg-black bg-opacity-70 flex items-center justify-center z-50 p-4">
            <div className="bg-white p-6 rounded-2xl shadow-2xl w-full max-w-sm">
                <div className="flex justify-between items-center mb-6">
                    <h3 className="text-xl font-extrabold text-indigo-700">{title}</h3>
                    <button onClick={onClose} className="text-gray-500 hover:text-gray-800">
                        <XCircle size={24} />
                    </button>
                </div>

                <input
                    type="email"
                    placeholder="Email Address"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    className="w-full p-3 mb-3 border border-gray-300 rounded-lg focus:ring-indigo-500 focus:border-indigo-500"
                />
                <input
                    type="password"
                    placeholder="Password (min 6 chars)"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    className="w-full p-3 mb-4 border border-gray-300 rounded-lg focus:ring-indigo-500 focus:border-indigo-500"
                />

                {error && <p className="text-sm text-red-500 mb-3 font-medium p-2 bg-red-50 rounded-lg"><AlertTriangle className='inline w-4 h-4 mr-1'/> {error}</p>}

                <button
                    onClick={handleSubmit}
                    disabled={loading || !email || !password}
                    className="w-full py-3 bg-indigo-600 text-white font-bold rounded-xl hover:bg-indigo-700 transition disabled:bg-gray-400"
                >
                    {loading ? <LoaderCircle size={20} className="inline animate-spin mr-2" /> : buttonText}
                </button>

                <div className="mt-4 text-center">
                    <button
                        onClick={() => { setIsLogin(!isLogin); setError(''); }}
                        className="text-sm text-indigo-600 hover:text-indigo-800 font-semibold"
                    >
                        {isLogin ? "Don't have an account? Sign Up" : "Already have an account? Log In"}
                    </button>
                </div>
            </div>
        </div>
    );
};

// --- Payment Modal (Razorpay Simulation) ---
const PaymentModal = ({ totalCost, onProcess, onCancel }) => {
    const [processing, setProcessing] = useState(false);

    const startProcessing = () => {
        setProcessing(true);
        setTimeout(() => {
            onProcess(); 
        }, 2000);
    };

    return (
        <div className="fixed inset-0 bg-black bg-opacity-70 flex items-center justify-center z-50 p-4">
            <div className="bg-white p-6 rounded-2xl shadow-2xl w-full max-w-sm">
                <h3 className="text-2xl font-extrabold text-indigo-700 mb-4">Confirm Payment</h3>
                <div className="p-4 bg-gray-100 rounded-lg mb-4">
                    <p className="text-sm text-gray-600">Amount to Pay:</p>
                    <p className="text-3xl font-extrabold text-red-600">₹{totalCost}</p>
                </div>
                
                <div className="space-y-3 mb-6">
                    <p className="text-sm font-semibold text-gray-700">Payment Gateway (Live Key):</p>
                    <div className="flex items-center p-3 border border-indigo-200 rounded-lg bg-indigo-50 text-xs font-mono truncate">
                       {RAZORPAY_PUBLISHABLE_KEY}
                    </div>
                    <input type="text" placeholder="Card Number or UPI ID (Simulated)" className="w-full p-3 border border-gray-300 rounded-lg"/>
                </div>

                <button
                    onClick={startProcessing}
                    disabled={processing}
                    className="w-full py-3 bg-green-600 text-white font-bold rounded-xl hover:bg-green-700 transition disabled:bg-gray-400"
                >
                    {processing ? (
                        <span className="flex items-center justify-center">
                            <LoaderCircle size={20} className="inline animate-spin mr-2" /> Processing Payment...
                        </span>
                    ) : (
                        `Pay ₹${totalCost} Securely`
                    )}
                </button>
                <button onClick={onCancel} disabled={processing} className="w-full mt-3 py-3 text-red-500 font-semibold rounded-xl hover:bg-red-50 disabled:text-gray-500">
                    Cancel Booking
                </button>
            </div>
        </div>
    );
};

// --- Map Tracker (OSM/Google Maps Key Placeholder) ---
const MapTracker = ({ nearestHelper }) => (
    <section className="mb-6 bg-white p-4 rounded-xl shadow-lg border border-gray-100">
        <div className="flex justify-between items-center mb-3">
        <h2 className="text-lg font-bold text-gray-800 flex items-center">
            <MapPin className="w-5 h-5 mr-2 text-red-500" />
            Live Helper Tracker (OpenStreetMap)
        </h2>
        <span className="text-sm font-extrabold text-indigo-600 bg-indigo-100 px-3 py-1 rounded-full">
            {nearestHelper ? `${nearestHelper.distance} KM Away` : 'Searching...'}
        </span>
        </div>
        
        <div className="relative w-full h-52 overflow-hidden rounded-lg border-2 border-gray-300 bg-gray-100">
            <div className="absolute inset-0 bg-map-pattern bg-repeat opacity-20"></div>
            
            <div className="absolute top-[40%] left-[30%] transform -translate-x-1/2 -translate-y-1/2">
                <MapPin className="w-8 h-8 text-green-600 fill-green-600 animate-bounce" />
                <span className="absolute -bottom-5 left-1/2 transform -translate-x-1/2 bg-green-600 text-white text-xs px-2 py-0.5 rounded-full shadow-lg">
                Helper
                </span>
            </div>

            <div className="absolute top-2 left-1/2 transform -translate-x-1/2 bg-white p-2 rounded-lg shadow-xl border-b-2 border-indigo-500 text-xs font-mono truncate">
                Map Key: {GOOGLE_MAPS_API_KEY.substring(0, 15)}...
            </div>
        </div>
    </section>
);

// --- Small Utility Components ---
const TaskCard = ({ task, selectedTask, setSelectedTask }) => {
    const Icon = task.icon;
    const isSelected = selectedTask === task.name;
    
    return (
      <div
        onClick={() => setSelectedTask(task.name)}
        className={`flex flex-col items-center justify-center p-3 rounded-xl cursor-pointer transition-all duration-200 shadow-md transform hover:scale-[1.03]
          ${isSelected ? 'bg-indigo-600 text-white ring-4 ring-indigo-300' : 'bg-white text-gray-700 hover:bg-indigo-50'}
        `}
      >
        <Icon className="w-6 h-6 mb-1" />
        <span className="text-xs font-medium text-center">{task.name.split(' ')[0]}</span>
      </div>
    );
};

const HelperCard = ({ helper }) => (
    <div className="bg-white p-4 rounded-lg shadow-md border-l-4 border-green-500 flex items-center mb-3">
        <div className="flex-shrink-0 mr-4">
        <div className="w-12 h-12 bg-gray-200 rounded-full flex items-center justify-center text-indigo-600 font-bold text-xl">
            <User size={24} />
        </div>
        </div>
        <div className="flex-grow">
        <p className="text-md font-bold text-gray-800">{helper.name}</p>
        <p className="text-xs text-gray-500 truncate">Specialty: {helper.specialty}</p>
        </div>
        <div className="flex flex-col items-end">
        <div className="flex items-center text-yellow-500">
            <Star size={14} fill="currentColor" className="mr-1"/>
            <span className="text-sm font-semibold">{helper.rating || 'N/A'}</span>
        </div>
        <span className="text-xs font-medium text-green-600 mt-1">
            {helper.distance ? `${helper.distance} KM away` : 'Location N/A'}
        </span>
        </div>
    </div>
);


// --- Main Customer App Logic ---
const AppContent = () => {
  const [db, setDb] = useState(null);
  const [auth, setAuth] = useState(null);
  const [user, setUser] = useState(undefined); // undefined means loading
  
  const [helperList, setHelperList] = useState([]);
  const [loadingHelpers, setLoadingHelpers] = useState(true);
  const [initError, setInitError] = useState(null); 
  const [showPaymentModal, setShowPaymentModal] = useState(false);
  const [showAuthModal, setShowAuthModal] = useState(false);

  const [selectedTask, setSelectedTask] = useState(tasks[0].name);
  const [estimatedHours, setEstimatedHours] = useState(2); 
  const [orderConfirmed, setOrderConfirmed] = useState(null); 
  
  // 1. Firebase Initialization and Auth Listener (STABLE FIX)
  useEffect(() => {
    const firebaseConfig = typeof __firebase_config !== 'undefined' ? JSON.parse(__firebase_config) : null;
    const initialAuthToken = typeof __initial_auth_token !== 'undefined' ? __initial_auth_token : null;

    if (!firebaseConfig) {
        setInitError("Firebase config not found.");
        setUser(null); 
        return;
    }

    try {
        const app = initializeApp(firebaseConfig);
        const firestore = getFirestore(app);
        const userAuth = getAuth(app);
        
        setDb(firestore); 
        setAuth(userAuth); 
        
        const authenticateUser = async () => {
            if (initialAuthToken) {
                await signInWithCustomToken(userAuth, initialAuthToken);
            } else if (!userAuth.currentUser) {
                await signInAnonymously(userAuth);
            }
        };
        authenticateUser();

        const unsubscribe = onAuthStateChanged(userAuth, (currentUser) => {
          setUser(currentUser); 
        });

        return () => unsubscribe(); 

    } catch (error) {
        setInitError(`Initialization Failed: ${error.message.substring(0, 50)}...`);
        setUser(null);
    }
  }, []);

  // 2. Helper Data Fetching
  useEffect(() => {
    if (!db || user === undefined) { 
        setLoadingHelpers(false); 
        return;
    }

    const appId = typeof __app_id !== 'undefined' ? __app_id : 'quick-helper-default';
    const helpersCollectionPath = `artifacts/${appId}/public/data/helpers`;
    const helpersRef = collection(db, helpersCollectionPath);
    const q = query(helpersRef, limit(10)); 
    
    setLoadingHelpers(true);

    const unsubscribe = onSnapshot(q, (snapshot) => {
      let helpers = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
      
      const helpersWithDistance = helpers
        .map(helper => {
            if (typeof helper.lat === 'number' && typeof helper.lng === 'number') {
                const distance = calculateDistance(USER_LOCATION.lat, USER_LOCATION.lng, helper.lat, helper.lng);
                return { ...helper, distance: parseFloat(distance) };
            }
            return { ...helper, distance: Infinity }; 
        })
        .filter(helper => helper.distance !== Infinity) 
        .sort((a, b) => a.distance - b.distance); 

      setHelperList(helpersWithDistance);
      setLoadingHelpers(false);

    }, (error) => {
      console.error("Firestore Error fetching helpers:", error);
      setLoadingHelpers(false);
      setHelperList([
        { id: 'd1', name: 'Rakesh Sharma', specialty: 'Electrician', rating: 4.8, lat: 19.1845, lng: 72.8415, distance: 1.2 },
        { id: 'd2', name: 'Sunita Devi', specialty: 'Cleaning', rating: 4.5, lat: 19.1901, lng: 72.8450, distance: 2.5 },
      ]);
    });

    return () => unsubscribe();
  }, [db, user]);


  const calculation = useMemo(() => calculateCost(estimatedHours), [estimatedHours]); 

  // 4. Order Submission Logic (Called AFTER Payment Simulation)
  const handleBooking = async () => {
    if (!db || !user?.uid || helperList.length === 0) {
        console.error("Booking failed: Auth, DB, or Helper issue.");
        return;
    }
    
    setShowPaymentModal(false); 
    
    const nearestHelper = helperList[0];

    const orderData = {
        task: selectedTask,
        estimatedHours: estimatedHours,
        totalCost: calculation.totalCost,
        helperId: nearestHelper.id,
        helperName: nearestHelper.name,
        orderStatus: 'Payment Successful - Pending Assignment', 
        timestamp: new Date().toISOString(),
        userLocation: USER_LOCATION,
        userId: user.uid, 
        paymentKeyUsed: RAZORPAY_PUBLISHABLE_KEY.substring(0, 10) + '...', 
    };
    
    const appId = typeof __app_id !== 'undefined' ? __app_id : 'quick-helper-default';
    
    try {
        const privateOrdersCollectionPath = `artifacts/${appId}/users/${user.uid}/orders`;
        const docRef = await addDoc(collection(db, privateOrdersCollectionPath), orderData);
        
        const publicOrdersCollectionPath = `artifacts/${appId}/public/data/pending_orders`;
        await setDoc(doc(db, publicOrdersCollectionPath, docRef.id), { ...orderData, id: docRef.id });

        const confirmedOrder = { id: docRef.id, ...orderData };
        setOrderConfirmed(confirmedOrder);

    } catch (e) {
        console.error("Error submitting order: ", e);
    }
  };


  // --- Render Logic ---
  
  if (initError) {
        return (
            <div className="flex items-center justify-center min-h-screen p-4">
                <div className="bg-red-100 p-6 rounded-xl border-2 border-red-500 text-red-800 text-center max-w-sm">
                    <AlertTriangle className="w-8 h-8 mx-auto mb-3"/>
                    <h3 className="font-bold text-xl">App Setup Failed</h3>
                    <p className="text-sm mt-2">{initError}</p>
                </div>
            </div>
        );
    }

  // Stabilization Fix: Display solid loader until user state is definitively known (not undefined)
  if (user === undefined) {
    return (
        <div className="flex items-center justify-center min-h-screen bg-white">
            <LoaderCircle className="w-10 h-10 animate-spin text-indigo-500"/>
            <span className="ml-3 text-lg font-semibold text-gray-700">Connecting to Service...</span>
        </div>
    );
  }
  
  const nearestHelper = helperList.length > 0 ? helperList[0] : null;
  const isUserLoggedIn = user && !user.isAnonymous && user.email; 

  return (
    <div className="min-h-screen bg-gray-50 font-sans p-4 flex flex-col items-center">
        {/* Modals */}
        {orderConfirmed && (
            <SuccessModal orderDetails={orderConfirmed} onClose={() => setOrderConfirmed(null)} />
        )}
        {showPaymentModal && auth && (
            <PaymentModal 
                totalCost={calculation.totalCost}
                onProcess={handleBooking}
                onCancel={() => setShowPaymentModal(false)}
            />
        )}
        {showAuthModal && auth && (
            <AuthModal auth={auth} onClose={() => setShowAuthModal(false)} />
        )}

      <header className="w-full max-w-md bg-white shadow-lg rounded-2xl p-4 mb-6 sticky top-0 z-10">
        <div className="flex justify-between items-center mb-1">
            <h1 className="text-2xl font-extrabold text-indigo-700 flex items-center">
              <BadgeCheck className="w-6 h-6 mr-2" />
              {APP_NAME}
            </h1>
            <button 
                onClick={() => setShowAuthModal(true)}
                className={`flex items-center p-2 rounded-full font-semibold transition-all ${isUserLoggedIn ? 'bg-green-100 text-green-700' : 'bg-indigo-100 text-indigo-700 hover:bg-indigo-200'}`}
            >
                {isUserLoggedIn ? <UserCheck size={18} /> : <LogIn size={18} />}
            </button>
        </div>
        
        <p className="text-sm text-gray-500 mt-1">User: {user?.email || `Guest ID: ${user?.uid.substring(0, 8)}...`}</p>
        <p className="text-xs font-mono text-gray-400 mt-1 truncate">Payment Key: {RAZORPAY_PUBLISHABLE_KEY.substring(0, 15)}...</p>

        <div className="flex items-center mt-3 p-3 bg-indigo-50 rounded-lg text-indigo-600">
          <LocateFixed className="w-4 h-4 mr-2" />
          <p className="text-sm font-semibold truncate">Current Location: Malad West, Mumbai</p>
        </div>
      </header>

      <main className="w-full max-w-md">

        <MapTracker nearestHelper={nearestHelper} />
        
        <section className="mb-6">
          <h2 className="text-lg font-bold text-gray-800 mb-3 flex items-center">
             <Users className="w-5 h-5 mr-2 text-indigo-500"/>
             Available Helpers (Sorted by Distance)
          </h2>
          
          {loadingHelpers ? (
            <div className="flex items-center justify-center p-8 bg-white rounded-xl shadow-lg">
              <LoaderCircle className="w-6 h-6 animate-spin mr-2 text-indigo-500" />
              <span className="text-gray-600">Loading Helper 
