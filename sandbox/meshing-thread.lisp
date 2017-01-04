(in-package :sandbox)

(defparameter mesher-thread nil)
(defun designatemeshing ()
  (unless (mesherthreadbusy)
    (if mesher-thread
	(getmeshersfinishedshit))
    (let ((achunk (dirty-pop)))
      (when achunk
	(giveworktomesherthread achunk)))))

(defun shape-list (the-shape)
 ;; (declare (optimize (speed 3) (safety 0)))
  (let ((ourlist (gl:gen-lists 1))
	(verts (shape-vs the-shape))
	(vertsize 6))
    (declare (type (simple-array single-float *) verts))
    (gl:new-list ourlist :compile)
    (macrolet ((wow (num start)
		 `(gl:vertex-attrib ,num
				    (aref verts (+ base (+ ,start 0)))
				    (aref verts (+ base (+ ,start 1)))
				    (aref verts (+ base (+ ,start 2)))
				    (aref verts (+ base (+ ,start 3)))))
	       (wow2 (num start)
		 `(gl:vertex-attrib ,num
				    (aref verts (+ base (+ ,start 0)))
				    (aref verts (+ base (+ ,start 1)))))
	       (wow3 (num start)
		 `(gl:vertex-attrib ,num
				    (aref verts (+ base (+ ,start 0)))
				    (aref verts (+ base (+ ,start 1)))
				    (aref verts (+ base (+ ,start 2)))))
	       (wow1 (num start)
		 `(gl:vertex-attrib ,num
				    (aref verts (+ base ,start)))))
      (gl:with-primitives :quads
	(dotimes (x (shape-vertlength the-shape))
	  (let ((base (* x vertsize)))
	    (wow1 8 5) ;darkness
	    (wow2 2 3) ;uv
	    ;;	    (wow 8 9)
	    ;;	    (wow 12 13)
	    (wow3 0 0) ;position
	    ))))
    (gl:end-list)
    ourlist))

(defun getmeshersfinishedshit ()
  (multiple-value-bind (coords shape) (sb-thread:join-thread mesher-thread)
    (if coords
	(if shape
	    (progn
	      (let ((old-call-list (lget *g/call-list* coords)))
		(when old-call-list (gl:delete-lists old-call-list 1)))
	      (lset *g/call-list* coords (shape-list shape))
	      (when worldlist (gl:delete-lists worldlist 1))
	      (setf worldlist (genworldcallist)))
	    (dirty-push coords))))
  (setf mesher-thread nil))

(defun mesherthreadbusy ()
  (not (or (eq nil mesher-thread)
	   (not (sb-thread:thread-alive-p mesher-thread)))))

(defun giveworktomesherThread (thechunk)
  (setf mesher-thread
	(sb-thread:make-thread
	 (lambda (chunk-position)
	   (sb-thread:return-from-thread
	    (values
	     chunk-position
	     (chunk-shape chunk-position))))
	 :arguments (list thechunk))))